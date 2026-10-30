> **CORREÇÃO DE AUDITORIA — 29/10, posterior aos testes:** O driver experimental calculava `arg.status` a partir de `rsp[0]`, mas não copiava a estrutura de volta ao userspace. Os zeros de status impressos pelo cliente não são evidência de sucesso. Captura, IRQ por toque, banco vazio, cadastro e autenticação não foram comprovados; as interpretações categóricas abaixo são históricas e não valem como conclusão. O JSON de build-info foi efetivamente observado. A rotação obrigatória de slots, causa de resets e segurança/posse do carveout continuam hipóteses não comprovadas; slots de 1 MiB aceitam frames de até 2 MiB e se sobrepõem. Não executar receitas de teste abaixo. Correção local do ioctl compilada, não instalada nem validada no aparelho; cliente novo rejeita driver antigo e trata status não zero conservadoramente (alguns comandos podem retornar valores positivos legítimos). Nenhuma partição foi escrita.

# Digital (FPC) no Linux — o TA FALA. Estado em 29/10/2026 ~20:00

## Resultado do dia (dados reais do aparelho, boot volátil)

1. **O TA `fpctzapp` carrega do Linux**: `QSEOS_APP_START_COMMAND` aceito pelo
   TEE, app_id devolvido na resposta.
2. **O TA responde comando** e devolveu o build info completo:
   `{"buildid_md5":"31193ede...","host":"sheldon-VirtualBox","date":"2021-02-24T11:36:48",
   "FPC_BUILD_TYPE":"debug","ENGINEERING":true,"SENSORTEST":true,"NAVIGATION":true,...}`
   com `+8=6`, `+0xc=0`, `+0x10=5`, `len=787` — exatamente o que o RE previu.
3. **Sensor vivo**: GPIO29 (enable), GPIO4 (reset) e GPIO90 (IRQ) via gpiolib;
   a IRQ do sensor dispara ao toque.
4. **Captura**: `m10 cmd 4/5` → status **1002 (0x3EA) sem dedo** e **0 com dedo**.
5. **Biometria**: `identify` executa (módulo 11 cmd 4) e responde
   "não reconhecido" com banco vazio — coerente.
6. **Enroll**: a sequência completa roda (amostras capturadas, `end_enrol`
   devolve 0), mas o template **não** foi aceito: o `identify` seguinte não casa.
   Falta tratar o status por amostra do módulo 11 (o TA devolve códigos 0..7).

## Os quatro segredos que destravaram (não perca isto)

a) **A região compartilhada TEM de estar no carveout `qseecom@9e400000`**
   (20 MiB, NOMAP na DT efetiva do U-Boot). Em qualquer outra memória o TEE
   recusa: em memória normal o SCM devolve -EINVAL; em CMA o TA falha ao
   registrar (`0xE850002A`, gerado em TA `0x38b8`).
b) **Variante *with whitelist* do send**: owner `TZ_APPS (48)`, svc 0, fn **6**,
   7 argumentos `(app_id, req, req_len, rsp, rsp_len, sglist, sglist_len)` com
   sglist = `{0x80000004, tamanho_da_região}` (bit31 = 1 endereço, bit30 = 0
   → 32 bits, offset 4 dentro do controle). Fonte do id: header
   `include/soc/qcom/qseecomi.h` (LineageOS sm6150), não invenção.
c) **Controle = {u32 tamanho_da_região PÁGINA-ALINHADO, u32 phys da região}**.
   O TA lê esses dois campos, registra a região e só depois roda o roteador.
   Bug que custou horas: `region_len` era calculado DEPOIS de escrever o
   controle → tamanho 0 → erro `0xE850002A`.
d) **Cada invocação precisa de um ENDEREÇO DE REGIÃO DIFERENTE**. Reusar a mesma
   região faz o TEE recusar (-EINVAL). A solução no driver é rotacionar 8 slots
   de 1 MiB dentro do carveout.

Extras aprendidos na marra:
- mapa **WB** sobre o carveout compartilhado **trava o aparelho** (incoerência);
  usar `memremap(MEMREMAP_WC)` + `memcpy_toio/fromio` com buffer de bounce;
- a **imagem do TA** deve ser alocada em memória normal (`dma_alloc_coherent`) —
  carregar do carveout é recusado;
- controle e sglist também ficam em memória normal; só a região de dados vai
  para o carveout;
- **módulo 10 cmd 0 = init do dispositivo**. Sem ele, cmd 1/2/3/4 estouram o TA
  (o TEE mata o app e toda chamada seguinte falha). O HAL chama cmd 0 primeiro.

## Como reproduzir (boot volátil)

```
fastboot boot work/PRE-GOLD-20261029-1534/uboot/u-boot-sm7150-motorola-hanoip-cam-tres.img
fastboot boot work/fingerprint-20261029/boot/kernel-hanoip-qseecom-fpc.img
scp qcom_qseecom_fpc.ko fpc-tac root@172.16.42.1:/tmp/
insmod /tmp/qcom_qseecom_fpc.ko region_phys=0 carveout_phys=0x9e400000 carveout_size=0x1400000
/tmp/fpc-tac --gpiochip /dev/gpiochip2 --irq 90 build-info
/tmp/fpc-tac --app-id <id> --gpiochip /dev/gpiochip2 --irq 90 sensor-init
/tmp/fpc-tac --app-id <id> --gpiochip /dev/gpiochip2 --irq 90 capture     # encoste o dedo
/tmp/fpc-tac --app-id <id> --gpiochip /dev/gpiochip2 --irq 90 identify
```

`region_phys=0` NÃO é opcional: a notificação de região (`fn 5`) é recusada (-22,
o ABL já configurou) e, se forçada para 0x86d00000, **travou o aparelho** — essa
faixa é memória viva do kernel neste boot.

## Artefatos

| arquivo | sha256 (início) |
| --- | --- |
| `Image.gz` (kernel com os helpers SCM) | `11b79bd3...` |
| `qcom_qseecom_fpc.ko` | `e48a65e3...` |
| `userspace/fpc-tac` (aarch64) | `c0f4e0ad...` |
| `boot/kernel-hanoip-qseecom-fpc.img` | boot.img com ramdisk do PRE-GOLD-1534 |

Fonte: `kernel/src/` + `kernel/apply.py` (idempotente) + `kernel/build.sh`.
Documento do protocolo: `docs/kernel/PROTOCOLO-FPC-TA-20261029.md`.
Checkpoint: `docs/kernel/checkpoint-2026-10-26-fingerprint-fpc.txt` (seção 29/10).

## Próximos passos óbvios

1. Decodificar o **status por amostra do módulo 11 cmd 2** (0..7) e o retorno de
   `end_enrol`; provavelmente o enroll falhou por qualidade/cobertura e o TA está
   devolvendo o motivo — hoje o tool ignora.
2. Ler os campos de resposta do `identify` (`+0xc` coverage, `+0x10` quality)
   para saber se a imagem está boa.
3. Módulo 4 (db blob) para persistir o template num arquivo e sobreviver a reboot.
4. Só depois pensar em integração libfprint/fprintd.
