# Protocolo do listener QSEECOM (RPMB/SSD) — levantamento 29/10

Fonte: `qseecom.c` do kernel Qualcomm (`kernel/msm-modules/securemsm`,
commit 30b672b6), baixado de android.googlesource.com. Arquivo local:
`qseecom.c` (10.177 linhas). Nada foi executado no aparelho.

## Por que isso é necessário

O TA do Keymaster não tem acesso ao RPMB. Ele executa `qsee_stor_*` e, quando
precisa de dados, o TEE pede ao mundo normal. No Android quem atende é o
`qseecomd` (listeners "RPMB system services", "SSD system services", gpfs), que
publica `vendor.sys.listeners.registered`.

## Mecânica exata (verificada no fonte)

1. O cliente manda o comando normalmente por SCM. Se o TEE precisar de um
   listener, a chamada **retorna antes de terminar** com
   `resp->result == QSEOS_RESULT_INCOMPLETE` e `resp->data = listener_id`.
2. O kernel localiza o listener registrado com esse id, marca
   `rcv_req_flag = 1`, invalida o cache do dmabuf dele e acorda a thread dele
   (`rcv_req_wq`). Em seguida o kernel **bloqueia** esperando a resposta.
3. A thread do listener (userspace) copia o pedido do seu buffer compartilhado,
   executa a operação e escreve a resposta no mesmo buffer; um ioctl de
   resposta acorda o kernel.
4. O kernel faz uma segunda chamada SCM com
   `QSEOS_LISTENER_DATA_RSP_COMMAND` (ou `..._WHITELIST`, que é o caso deste
   aparelho, `whitelist_support=1`) contendo `listener_id`, `status` e o
   tamanho. **A resposta dessa chamada é a continuação da resposta do cliente**:
   o laço continua enquanto vier `INCOMPLETE`.

Detalhe: para `RPMB_SERVICE` e `SSD_SERVICE` o kernel liga o clock QSEE antes de
responder.

## Constantes confirmadas no fonte

| item | valor |
| --- | --- |
| `RPMB_SERVICE` (listener id) | `0x2000` |
| `SSD_SERVICE` | `0x3000` |
| tamanho do buffer do listener RPMB | `0x6400` (25600 B), visto em `rpmb_start` do librpmb |
| serviço SCM usado | `SCM_SVC_TZSCHEDULER` (1) |
| comandos | `QSEOS_REGISTER_LISTENER`, `QSEOS_DEREGISTER_LISTENER`, `QSEOS_LISTENER_DATA_RSP_COMMAND` (+ variante `_WHITELIST`) |
| resultado de "precisa de listener" | `QSEOS_RESULT_INCOMPLETE` |

Os valores numéricos dos comandos estão no uapi (`include/uapi/linux/qseecom.h`)
e podem ser confirmados também em runtime: a resposta `INCOMPLETE` carrega o
`listener_id` em `resp->data`.

## O que o listener RPMB faz com o pedido

`librpmb.so` implementa o lado do serviço:
`QSEECom_register_listener(cb, 0x2000, 0x6400, 0)`, uma thread `dispatch` e
`rpmb_read`/`rpmb_write` sobre `/dev/sg*` com SG_IO e ioctls de query do UFS.
Não há HMAC/sha256 no librpmb: **os frames RPMB chegam já autenticados do TEE**;
o HLOS só transporta. É por isso que a chave do RPMB nunca sai do TEE.

## Consequências para o Kali

* `CONFIG_RPMB` do kernel 7.3 **não resolve**: `drivers/misc/rpmb-core.c` é uma
  API interna (`rpmb_route_frames`), sem `/dev`, sem ioctl e sem chave;
  `drivers/ufs/core/ufs-rpmb.c` só entrega `struct rpmb_frame` ao dispositivo.
  Nada disso atende o protocolo do listener.
* O caminho certo é implementar o listener no nosso módulo QSEECOM:
  registrar `0x2000` com um buffer no carveout, tratar `INCOMPLETE`, executar
  os frames via `/dev/bsg/0:0:0:49476` (o mesmo LUN que já existe) e responder
  com `QSEOS_LISTENER_DATA_RSP_COMMAND_WHITELIST`.
* `qseecom.qsee_reentrancy_support = 2` neste aparelho (visto no dmesg do
  Android), então o fluxo de reentrância precisa ser respeitado: a resposta do
  listener vai por uma chamada SCM separada, não pela mesma do cliente.

## Riscos

* Kernel novo + boot volátil: cada iteração exige reconstruir e reiniciar.
* Se o listener responder errado, o TEE pode ficar bloqueado esperando; é
  necessário timeout e um caminho de aborto seguro.
* Qualquer gravação no RPMB é decisão do TEE (é ele que assina). Nosso listener
  não escolhe o que gravar; apenas transporta.
