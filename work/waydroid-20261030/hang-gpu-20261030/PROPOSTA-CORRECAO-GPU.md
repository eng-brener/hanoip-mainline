# GPU travada no hanoip — por que o kernel não recupera e o que daria para fazer

> **Correção de 30/10:** as explicações causais e o plano abaixo são hipóteses,
> não resultados comprovados. O driver já possui recuperação e `force_off`;
> não foi demonstrado que resumes rearmaram o watchdog nem que drenar fences
> devolveria a tela. Forçar fences a sucesso pode corromper estado e não é uma
> correção validada; não implementar sem revisar a semântica de erros e testes.
> Também não foi demonstrado que llvmpipe esteja efetivamente renderizando ou
> impeça o uso da GPU. A largura de endereço e o mecanismo do fault precisam
> ser verificados; não concluir que o ponteiro é inválido só por ter 40 bits.

Análise de código feita em 30/10/2026 sobre `kernel-mainline/` (7.3, árvore do
PRE-GOLD #64). **Nada disto está implementado**: é o levantamento e a proposta,
para decidir depois. Evidência do travamento em `DIAGNOSTICO.md` (nesta pasta).

## 1. Caminho de código percorrido no travamento

| Arquivo:linha | O que faz |
|---|---|
| `adreno/a6xx_gmu.c:46-50` | `a6xx_gmu_irq()` vê `WDOG_BITE`, faz `dev_err_ratelimited("GMU watchdog expired")` e chama `a6xx_gmu_fault()` |
| `adreno/a6xx_gmu.c:22-36` | `a6xx_gmu_fault()`: `gmu->hung = true`, `timer_delete(hangcheck)`, `kthread_queue_work(recover_work)` |
| `msm_gpu.c:464` `recover_worker()` | acha o submit culpado, incrementa faults, `msm_gem_vm_unusable()` quando `!vm->managed`, captura crashstate, **sobe a fence do submit culpado em +1**, `retire_submits()`, chama `gpu->funcs->recover()` e **re-submete** o resto da fila (com `nr_cmds = 0` se a VM ficou unusable) |
| `adreno/a6xx_gpu.c:1561` `a6xx_recover()` | halta o SQE, `hung = true`, tira autosuspend, zera `active_submits`, **derruba o GDSC do CX** (`dev_pm_genpd_synced_poweroff`), espera `pd_gate` 1 s, `pm_runtime_put_sync()` → suspensão → `a6xx_gmu_stop()` |
| `adreno/a6xx_gmu.c:1478` `a6xx_gmu_stop()` | com `gmu->hung` chama `a6xx_gmu_force_off()` |
| `adreno/a6xx_gmu.c:1121` `a6xx_gmu_force_off()` | `hfi_stop`, `a6xx_gmu_irq_disable`, **`a6xx_sptprac_disable` (falhou: 0x28)**, `gemnoc_workaround`, `rpmh_off`, limpa AHB fence, `CM3_SYSRESET=1`, `bus_halt` |
| `adreno/a6xx_gmu.c:1074` `a6xx_gmu_irq_disable()` | `disable_irq(gmu_irq)`, `disable_irq(hfi_irq)` (**síncrono** — não pode ser chamado de dentro do handler), mascara `AO_HOST_INTERRUPT_MASK` e `GMU2HOST_INTR_MASK` |
| `msm_gpu.c:825` | `hangcheck_timer_reset()` é rearmado no resume |

## 2. Por que o aparelho NÃO se recupera

1. **A GMU não volta.** A recuperação depende de desligar a GMU (`force_off` →
   `sptprac_disable` → `CM3_SYSRESET`). Com a GMU já fora de estado, o
   `sptprac_disable` não confirma (`0x28`) e o hardware continua afirmando
   `WDOG_BITE`.
2. **O ciclo se repete.** `force_off` mascara/desabilita as IRQs, mas qualquer
   `pm_runtime` resume depois disso reabilita (`a6xx_gmu_irq_enable`) e rearma o
   hangcheck → watchdog → fault → recover → ... Foi isso que gerou
   **1,6 milhão de callbacks em ~5 s** (`a6xx_gmu_irq: N callbacks suppressed`)
   e load average 8–10, com a tela congelada.
3. **As fences nunca completam.** O `recover_worker` re-submete a fila, mas a
   fence de um submit só avança quando **a GPU escreve** no `memptrs`. GPU morta
   = ninguém escreve. `msm_update_fence()` só é chamado para os submits já
   retirados (o culpado +1). Resultado: `dma_fence_default_wait` eterno no
   `phoc` (é exatamente o `wchan` que medimos) e em qualquer app que espere a
   GPU — congelamento total, sem nem o SSH adiantar para restaurar a tela.

## 3. Proposta camada 1 — fail-safe (baixo risco, só roda no fault)

Objetivo: **parar de fingir que recupera**. Em vez de storm + congelamento,
falha controlada:

1. **Estado novo** `gmu->dead` (bool) no `struct a6xx_gmu`.
2. **Handler** (`a6xx_gmu_irq`): se `WDOG_BITE` e já estamos em `hung`/`dead`,
   não agendar nada: `disable_irq_nosync(gmu->gmu_irq)`,
   `disable_irq_nosync(gmu->hfi_irq)` e mascarar os dois registradores de
   interrupção; logar **uma única vez** ("GPU morta: reinicie"). Isso mata o
   storm sem depender do `disable_irq()` síncrono (que travaria no handler).
3. **Detecção de "não recuperou"**: contador de faults da GMU; se o watchdog
   voltar depois de um `recover`, marca `dead = true` e não reabilita mais.
4. **Drenar as fences** (em `recover_worker`/novo helper): para cada ring,
   `msm_update_fence(ring->fctx, ring->submitted_fence)` e `retire_submits()`;
   marcar **todas** as VMs como `unusable` para que submits novos virem no-op.
   Aí nenhum processo fica esperando para sempre. Efeito colateral honesto: o
   userspace pode ver a fence "completar" sem o trabalho ter rodado (render
   errado em vez de travar) — para compositor é melhor que congelar.
5. **Banner** único em kmsg/dmesg com instrução de reiniciar.

Ganho medido que dá para esperar: load volta a ~1, `/proc/interrupts` para de
crescer, SSH responde, log limpo. **Não** devolve a tela: GPU morta continua
morta, e o reboot segue necessário.

## 4. Proposta camada 2 — reset de verdade (experimento, sem garantia)

Tentar, no caminho `dead`: `force_off` → cortar de fato GX/CX (regulador/GDSC)
→ religar → `a6xx_gmu_start()` (recarrega firmware e HFI) → reinit do GPU. Isso
é o que o downstream (kgsl) faz com "GPU recovery". Sem linha de reset
dedicada, a GMU pode ficar em estado indefinido; e sem repro confiável do fault
não há como validar de forma repetível. Só depois da camada 1.

## 5. Como validar (repro)

Programa de userspace com o UAPI do msm (`msm_drm.h`): criar BO, montar um IB
com `CP_MEM_WRITE` para um IOVA **inválido** e submeter. Isso gera um fault de
CP igual ao que vimos (`ttbr0=... source=CP`) e exercita hangcheck →
`recover_worker` → `a6xx_recover`. Com isso dá para:
- medir se a GPU volta **sem** o fail-safe (reproduz o bug do Waydroid);
- medir o comportamento **com** o fail-safe (storm some, fences completam).
Cuidado: pode matar a GPU de propósito — só rodar em boot volátil e com o
procedimento de reboot (VOL- + `fastboot boot` do PRE-GOLD) à mão.

## 6. Alternativa de custo zero (a que já está em teste)

Não deixar o guest submeter na GPU (`MESA_LOADER_DRIVER_OVERRIDE=llvmpipe` via
wrapper no zygote, ver `onde paramos.md`). Evita o fault na origem em vez de
tratar o sintoma.

## 7. Estado

- Nada implementado, nada commitado.
- A árvore do kernel é `work/kernel-7.3/v7` (`build.sh` + `mkimg-kali.sh`);
  qualquer patch aqui exige rebuild + `fastboot boot` (volátil).
- Decisão de escopo pendente com o usuário (camada 1 / 1+repro / 1+2).
