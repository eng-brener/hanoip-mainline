# Waydroid 1.6.3 no hanoip — travamento da GPU (30/10/2026 ~15:16)

Kernel PRE-GOLD-20261030-1430 (#64, `7.3.0-sm7150`, listener7), U-Boot cam-tres.
Sessão Phosh/Phoc do Kali + Waydroid (imagem LineageOS 20 GAPPS, vendor MAINLINE).

Arquivos de evidência nesta pasta (lidos do aparelho, só leitura):

- `klog-hang.log` — `journalctl -b -k` de 15:12 até 15:23 (spmi filtrado)
- `journal-hang.txt` — janela 15:16:20–15:17:10 sem o flood do PMIC
- `dmesg-ring.txt` — dmesg no momento da coleta (já rotacionado; o fault saiu do ring)
- `../shots/*.png` — telas (spinner, boot animation do LineageOS, app grid)

## Linha do tempo

| hora | evento |
|---|---|
| 15:10:06 | 1ª subida do Waydroid: `session start` + `show-full-ui` |
| 15:10:09 | **phosh morre com SIGSEGV** (`ANOM_ABEND sig=11`), sessão gráfica inteira cai e reinicia às 15:10:35 |
| 15:10:10 | hwcomposer do Waydroid: `Wayland client was disconnected: Broken pipe`; SurfaceFlinger morre |
| (após o restart) | bind do socket `/run/xdg/wayland-0` aponta para o socket MORTO do phoc antigo → `Couldn't open Wayland display` em loop |
| 15:15:58 | sessão Waydroid reiniciada depois de `session stop` + `systemctl restart waydroid-container` (bind novo, socket válido) |
| 15:16:03 | Android desenha a boot animation na tela (confirmado por screenshot) — GPU funcionando |
| **15:16:32** | **`arm-smmu 15000000.iommu: Unhandled context fault: fsr=0x402, iova=0x00000400, fsynr=0x140023, cbfrsynra=0xc40, cb=10`** |
| **15:16:48** | **GPU hangcheck: lockup no ring 0 (fence 16131 de 16139); offending task: `RenderThread (com.android.launcher3)`** |
| **15:16:48** | **`*** gpu fault: ttbr0=000000013976e000 iova=000000e040080980 dir=WRITE type=TRANSLATION source=CP`** |
| 15:16:50 | `a6xx_sptprac_disable: failed to power off SPTPRAC: 0x28` (a recuperação da GPU falhou) |
| 15:16:51 → | `GMU watchdog expired` em loop (1,6 milhão de IRQs em 5 s, "callbacks suppressed") |
| daí em diante | phoc preso em `dma_fence_default_wait`; tela congelada; nada recupera |

## Por que travou (causa)

1. **Foi um fault de GPU gerado pelo Android convidado.** O task culpado é
   `com.android.launcher3` / `RenderThread`: o *command processor* (CP) da Adreno
   618 tentou **escrever** em `iova=0xe040080980`. Esse endereço tem ~40 bits e
   não existe no espaço do MMU da GPU (36 bits) — ou seja, o stream de comandos
   chegou com um ponteiro corrompido/lixo. O kernel marcou tradução inválida
   (`type=TRANSLATION`) e o ring parou (fence 16139 submetida, 16131 completada).

2. **O fault anterior (15:16:32) é no contexto do display.** `SID=0xc40` casa com
   `display-subsystem@ae00000` cujo DT efetivo é `iommus = <&apps_smmu 0x800
   0x440>` (o 0xc40 = 0x800 | 0x400 | 0x040 está coberto pela máscara), `cb=10`,
   e o acesso foi ao IOVA `0x400` — um endereço "quase nulo" no caminho gráfico.
   Ou seja: 16 s antes do CP morrer, o pipeline gráfico já acessava endereço
   inválido. Ambos apontam para buffer/mapeamento inválido na pilha
   Waydroid(minigbm/gralloc.gbm) → Mesa/freedreno → msm → DPU.

3. **O kernel não consegue recuperar.** `recover_worker` chamou `a6xx_recover`,
   que tenta desligar SPTPRAC/GMU e **falhou (`0x28`)**: o GMU ficou com o
   watchdog disparando para sempre. A partir daí `a6xx_gmu_irq` só loga; não há
   reset de GMU nesse caminho. O phoc fica esperando um `dma_fence` que nunca
   será sinalizado → tela congelada, e nem matar o Android libera (tentado).

4. Detalhe relevante do próprio kernel: o UAPI novo de **VM_BIND**
   (`include/uapi/drm/msm_drm.h`, `MSM_PARAM_EN_VM_BIND`) diz explicitamente que,
   quando o userspace liga VM_BIND, **o kernel não tenta recuperar de GPU faults**.
   O kernel 7.3 tem esse UAPI, e a Mesa do guest (imagem MAINLINE) é candidata a
   usá-lo. Isso torna o fault fatal por desenho.

## Contexto: a primeira tentativa já tinha derrubado o Phosh

Antes do hang, às 15:10:09, o **phosh morreu com SIGSEGV** no instante em que o
hwcomposer do Waydroid conectou e apresentou o primeiro frame. A sessão reiniciou
sozinha, mas o bind do socket Wayland dentro do container ficou apontando para o
socket morto — por isso o Waydroid não voltava (`Couldn't open Wayland display`).
O `restart` da sessão resolveu isso (aí a boot animation apareceu).

Conclusão: a pilha gráfica (phosh/phoc + freedreno + DMABUF do Waydroid) já se
mostrou frágil **duas vezes** nesta sessão: crash do compositor e wedge da GPU.

## O que NÃO é a causa

- Não é falta de memória: 674 MB livres + 1,5 GB de cache no momento do fault.
- Não é temperatura nem bateria: o log de SPTPI é o ruído normal de carga.
- Não é o `hanoip-gpu-floor` (só vota frequência mínima; o fault é de endereço).
- Não é o dvfs: `trans_stat` mostra a GPU trabalhando normal em 355/800 MHz.

## Como evitar daqui pra frente

1. **Curto prazo (recomendado):** não deixar o Waydroid rodando com renderização
   por GPU enquanto a sessão for a que você usa para trabalhar. Se for testar de
   novo, testar imediatamente depois de um boot limpo, sabendo que o preço de um
   fault é reiniciar o aparelho (a GPU não volta).
2. **Mitigação possível:** forçar o guest a não usar a GPU para GLES
   (`ro.hardware.egl=swiftshader` no `waydroid.prop`), deixando só o compositor
   do hwcomposer em cima da GPU. O launcher deixa de submeter stream próprio.
   Não testado.
3. **Correção de verdade (kernel):** melhorar o caminho de erro do `a6xx_gmu`
   para resetar a GMU quando o SPTPRAC não desliga, em vez de entrar em flood de
   watchdog — e/ou evitar VM_BIND para o contexto do guest.
4. **Relatar upstream:** fault de CP com iova de 40 bits vindo do freedreno do
   guest + falta de recuperação de GMU é bug de driver, não configuração.

## Como sair do estado travado

A GPU não volta com software. Só reiniciando. **Reiniciar segurando VOL-**
para cair no fastboot da Motorola (o U-Boot e o kernel são voláteis; se cair no
Android, o rootfs Kali em userdata corre risco). Depois, do Mac:

```
fastboot boot work/PRE-GOLD-20261030-1430/uboot/u-boot-sm7150-motorola-hanoip-cam-tres.img
fastboot boot work/PRE-GOLD-20261030-1430/kernel/kernel-hanoip-listener7.img
```
