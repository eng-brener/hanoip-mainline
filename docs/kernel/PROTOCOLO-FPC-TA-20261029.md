> **CORREÇÃO DE AUDITORIA — 29/10, posterior aos testes:** O driver experimental calculava `arg.status` a partir de `rsp[0]`, mas não copiava a estrutura de volta ao userspace. Os zeros de status impressos pelo cliente não são evidência de sucesso. Captura, IRQ por toque, banco vazio, cadastro e autenticação não foram comprovados; as interpretações categóricas abaixo são históricas e não valem como conclusão. O JSON de build-info foi efetivamente observado. A rotação obrigatória de slots, causa de resets e segurança/posse do carveout continuam hipóteses não comprovadas; slots de 1 MiB aceitam frames de até 2 MiB e se sobrepõem. Não executar receitas de teste abaixo. Correção local do ioctl compilada, não instalada nem validada no aparelho; cliente novo rejeita driver antigo e trata status não zero conservadoramente (alguns comandos podem retornar valores positivos legítimos). Nenhuma partição foi escrita.

# Protocolo do TA FPC (fpctzapp) — decodificação estática, 29/10/2026

Objetivo: ter o mapa completo do que um cliente Linux precisa falar para usar o
leitor de digitais deste aparelho **sem** depender do HAL Android.

Tudo aqui é engenharia reversa estática de artefatos já coletados. Nada foi
executado no alvo, nenhum comando foi enviado ao TEE e o aparelho não foi
tocado (ele não estava conectado).

Artefatos de origem (hashes conferidos com o dump do aparelho):

| Arquivo | Origem | Tamanho |
| --- | --- | --- |
| `fpctzapp.mdt` + `.b00..b07` | partição `modem_a` (`/vendor/firmware_mnt/image`) | 7260 B + 8 segmentos |
| `fingerprint-service-fpc` (HAL) | `/vendor/bin/hw/` | 176080 B |
| `fpc_tee_test` | `/vendor/bin/` | 55168 B |
| `fpc_ident` | `/vendor/bin/hw/` | 20688 B |

Mapa legível por máquina: `work/fingerprint-20261026/protocol/fpc-protocol.json`.
Notas dos módulos 3/4/11 e 5: `protocol/notes/`.

## 1. Transporte (ABI QSEECOM legada)

1. `QSEECom_start_app(handle, "fpctzapp", 128)` — buffer de controle de **128**
   bytes (HAL 0x22b1c: `str w8,[x19,#8]` com w8=0x80; 0x22b20).
2. O HAL descobre o caminho do dispositivo por
   `fpc_sysfs_path_by_attr("/sys/class/fingerprint", ...)` e abre o atributo
   (HAL 0x22ae0), mas o conteúdo não é usado no protocolo do TA.
3. Cada comando:

```
control[0x00] = tamanho da região externa        (HAL 0x22e2c)
control[0x04] = endereço físico da região externa ← PATCHED pelo kernel
control[0x08..0x3f] = zeros
control[0x40..0x7f] = resposta de 64 B; control[0x40] = status do TEE
```

   O patch é pedido por `QSEECom_ion_fd_info{fd = req->ion_fd, cmd_id = 4}`
   (HAL 0x22e10/0x22e40: `stp w9, w10, [sp,#8]` com w10 = 4).
4. A região externa é alocada por `ion_alloc_fd` (alinhamento 4096, flag
   `0x08000000`) e mapeada com `mmap(PROT_READ|PROT_WRITE, MAP_SHARED)`
   (HAL 0x22c94–0x22d08). No `fpc_tee_init` o tamanho é **5264 bytes**
   (HAL 0x1df9c: `mov w1,#0x1490`); cada comando que precisa de mais
   (`build_info`, `debug_retrieve`) aloca o seu.
5. O TA **não** lê a região externa direto: copia para um buffer interno,
   despacha e copia de volta (TA 0x3908: `memcpy` → `bl 0x1a8` → `memcpy`).
   Ou seja, o frame é lido e escrito in place.
6. Status: o primeiro word da resposta de 64 B. Negativo = erro. **-14
   (`0xFFFFFFF2`) = ocupado**: o HAL dorme 10 ms e repete uma vez, depois
   dorme 20 ms e devolve -13 (HAL 0x214e4–0x21538, mesma política no TA).

## 2. Formato do frame

**Não existe um layout único depois de `+0x04`.** Os primeiros 8 bytes são
sempre `{module_id, cmd_id}`; do `+0x08` em diante cada módulo define os seus
campos. Duas convenções foram medidas:

**(a) módulos 3, 4, 5, 11 — `+8` = tamanho/valor, payload em `+0x0c`:**

```
+0x00 u32 module_id
+0x04 u32 command_id
+0x08 u32 tamanho/valor (in e out)
+0x0c ... payload (a resposta sobrescreve o mesmo buffer)
```

Prova: roteador `0x214 ldr.w r4,[r12,#8]` + `0x21a add.w r5,r4,#0xc` +
`0x21e cmp r5,r1`; módulo 4 `0x414a add.w r0,r6,#0xc`. O limite de resposta
nesses módulos **não é campo do frame**: é o argumento `r1` (tamanho do buffer)
que o TEE passa ao handler (`0x23c bx r3` → `handler(frame, buflen, cmd)`).

**(b) módulo 12 — limite em `+0x14`, payload em `+0x18`:**

```
+0x14 u32 limite de resposta (in, máx 0x400)
+0x18 ... payload
```

**(c) módulo 10 — campos fixos próprios:** `+8` flags/arg, `+0xc` modo,
`+0x10` saída, `+0x14` limite.

Tamanho mínimo do buffer por módulo (checado no handler): 12 → `0x418`,
10 → `0x70`, 5 → `0x34`, 4 → `0x70`, 11 → `0x70`, 3 → `0x10`.

O frame **não** cabe nos 64 bytes do controle: ele vive na região externa
alocada por fd (ION), e é aí que 1,7 MB de banco de digitais atravessa.

## 3. Tabela de módulos do TA

Tabela de 8 ponteiros em `0x116000`; struct do módulo: `+0x4` = início do
despacho, `+0x8` = handler chamado pelo roteador, `+0xc` = id.
Roteador em `0x1a8` (`fpc_ta_route_command`): exige `len >= 8`, procura o id,
aceita `cmd <= N`, faz tail-call `handler(frame, len, cmd)`.

| id | módulo | handler | observação |
| --- | --- | --- | --- |
| 12 | common | `0x328` | build info |
| 11 | bio | `0x420` | enrol/identify/templates |
| 10 | sensor | `0xcc0` | init, captura, OTP, sleep |
| 9 | kpi | `0x2cba` | métricas |
| 8 | navigation | `0x44c0` | fora do escopo |
| 5 | sensortest | `0x4324` | testes de fábrica (não devolve imagem) |
| 4 | db_blob | `0x4048` | banco de templates (blob do host) |
| 3 | hw_auth | `0x3da4` | gatekeeper/desafio |

**Módulo 6 não existe neste TA.** O HAL tem comandos para ele
(`fpc_tee_debug_retrieve` usa `{6,1}`; `get_raw_size` usa `{6,4}`), então esse
caminho de imagem crua falha no aparelho. A imagem crua tem de vir do módulo 5.

Índice dos pares `{module, cmd}` usados pelo HAL (`.rodata` 0xe090..0xe1e8,
40 entradas): cada função que envia comando carrega um par de 8 bytes
(`ldr d0,[x8,#imm]`) e grava em `frame[0..8]`. Exemplos verificados:
`{12,1}` = build info, `{12,0}` = no-op, `{10,7}` = OTP, `{5,*}` = testes,
`{4,6}` = db blob.

## 4. Módulo 12 (common)

**cmd 1 — get_build_info** (TA 0x328–0x3aa):

```
in : +0x14 = limite (máx 0x400; senão erro 0xE8A08033)
out: +0x08 = 6
     +0x0c = 0
     +0x10 = 5
     +0x14 = strlen(json)+1
     +0x18 = JSON de build (NUL incluso)
erro: 0xE8A08031 se não couber; 0xE8A08057 se frame < 0x418
```

O JSON já extraído do próprio TA: build de 24/02/2021, tipo debug,
`ENGINEERING=true`, `SENSORTEST=true`, `NAVIGATION=true`.

## 5. Módulo 10 (sensor)

**Correção da tabela abaixo:** os bytes da tabela TBB foram lidos invertidos
em cada meia-palavra. A tabela correta é: cmd 0 → `0xd02` (init), cmd 1 →
`0xd7a` (finger-lost), cmd 2 → `0xdb0`, cmd 3 → `0xdbc`, cmd 4 → `0xdc8`
(captura), cmd 5 → `0xe8c` (deep sleep). Os destinos restantes também devem
ser recalculados antes de uso. A descrição abaixo está preservada como histórico.
Evidência: instrução TBB em `0xcf2`, bytes reais `06 42 5d 63 69 cb ...` e
análise REA `ev_077366e3717c9e0cd5f5647a430437057f8234d8dd2005d447be469d1c025c5a`.

Entrada comum: o handler chama **`fpc_sensor_communication_start`** (0x11209)
antes de tudo; se falhar, retorna erro sem despachar.
Despacho por `tbb` em `0xcf2`, tabela em `0xcf6` (`42 06 63 5d cb 69 e6 d1 5b
d9 00 de`), frame mínimo `0x70`.

| cmd | destino | o que faz (evidência) |
| --- | --- | --- |
| 0 | `0xd7a` | `fpc_sensor_check_finger_lost(dev, frame+8)`; status decodificado; devolve 1 ou 2; se 3 e `frame+0xc != 0` roda `fpc_test_dead_pixel_update` |
| 1 | `0xd02` | `fpc_device_open` → `fpc_ta_common_init` → `fpc_device_init(flags=frame+8)` → `fpc_device_get_sensor_unique_id` → grava o id em `frame+0x10` |
| 2 | `0xdbc` | `fpc_sensor_wakeup_setup` |
| 3 | `0xdb0` | `fpc_sensor_finger_lost_wakeup_setup` |
| 4 | `0xe8c` | `fpc_sensor_deep_sleep` |
| 5 | `0xdc8` | **captura**: `capture_details_init`; `flags = frame+8` (byte); `frame+0xc` e `frame+0x14` (limite) alimentam o laço de qualificação/detecção; se `flags == 0` faz `fpc_device_power_wakeup`; laço de até 60 iterações com `fpc_get_timestamp`; escreve o **status da captura em `frame+0x10`**. A imagem fica no buffer interno do TA (não vai para o frame) |
| 6 | `0xec2` | cai no exit comum (não implementado) |
| 7 | `0xe98` | `fpc_otp_get_sensor_info(dev, frame+8)` — info do OTP a partir de `+0x8` |
| 8 | `0xdac` | no-op com sucesso |
| 9 | `0xea8` | retorna `0xE8F10125` (**não suportado neste build**) |
| 10 | tabela | entrada inválida (byte 0x00 → `0xcf6`). **Nunca enviar** |

### Fluxo de captura do HAL (HAL 0x216c0, `fpc_tee_capture_image_internal`)

```
frame+8  = flags (u8)      [0x2173c]
frame+0xc = 0              [0x21740]
frame+0x14 = ctx->0x4c     (limite) [0x21744/0x21748]
se flags != 0: habilita wakeup da IRQ [0x21754]
cmd 1  [0x2177c]
cmd 2  [0x2178c]
cmd 3  [0x21804]
fpc_irq_wait(ctx->irq, 1)  [0x21818]
cmd 4  → status lido de frame+0x10 e guardado em ctx+0x48 [0x218d0-0x218e4]
cmd 5  [0x21990]
repete o ciclo até 4 vezes enquanto o status for 1 [0x21734, 0x21948]
```

O sender dedicado é `0x21478`: grava `{10, cmd}` no frame e chama o transporte
(0x214a8: `stp w9(=10), w1(=cmd), [x8]`), com a política de retry em -14.

## 6. Módulo 5 (sensortest) — frame mínimo `0x34`

Handler `0x4324` aceita `len >= 0x34` e **cmds 0..6** (`0x4364`); tabela `tbb`
em `0x436e` = `04 09 0e 13 27 4d 48`.

| cmd | handler | efeito |
| --- | --- | --- |
| 0 | `0x4376` | `fpc_test_self_test_init`; sai status em `+0x2c` |
| 1 | `0x4380` | `fpc_test_run_self_test`; entra `+0x2c`, sai `0`/5/6/`0x10` |
| 2 | `0x438a` | `fpc_test_self_test_cleanup` |
| 3 | `0x4394` | `fpc_test_is_*_supported` para o id em `+0x8` (1 = suportado) |
| 4 | `0x43bc` | **run_test**: tipo em `+0x8` (1..9), 28 B de parâmetros em `+0x0c..+0x27`; saída `+0x28` = resultado/qualidade, `+0x2c` = status, `+0x30` = tamanho do log |
| 5 | `0x4408` | buraco: cai no epílogo com `0xE8A1C0CE` |
| 6 | `0x43fe` | `fpc_device_capture_uncalibrated_image(dev, ctx)` — captura para o contexto interno do TA e dorme o sensor |
| 7 | — | **não despachado** (o HAL usa `{5,7}` para `get_log`) |

Layout do frame do módulo 5:

```
+0x00 module=5, +0x04 cmd
+0x08 u32  test id (cmd 3/4) | tamanho in/out (cmd 7, morto)
+0x0c u32[7] = 28 B de parâmetros (cmd 4, in/out)
+0x28 u32  resultado/qualidade
+0x2c u32  status / valor de pino de IRQ
+0x30 u32  tamanho do log
```

Tipos do `cmd 4` (enum do host, tabela `fpc_sensortest_tests` @ `0x27940`):
0 Self Test · 1 Checkerboard · 2 Image Quality · 3 Reset Pixel · 4 AFD Calibration ·
5 AFD Cal · 6 Module Quality · 7 Defective Pixels · 8 OTP Validation ·
9 TXPulse Checkerboard · 10–12 ESD Check Pre/Check/Post.
O HAL reescreve **`test id 1 → 7`** antes de enviar (`0x20044`), então o
`-b/checkerboard` do utilitário executa `fpc_test_defective_pixels_test` do TA e
o tipo 1 do TA fica inalcançável por essas APIs.

**A imagem crua não sai do TEE por caminho nenhum**: o módulo 5 só captura para o
contexto interno (`fpc_sensor_driver_capture_image(driver, 0x10, 0, ctx, 0)`), o
módulo 6 (que faria `retrieve`) não existe e o `get_log` do módulo 5 (`{5,7}`)
também não é despachado — `fpc_test_get_log` não tem nenhum chamador no TA.
Consequência: verificação de dedo acontece **dentro** do TA (módulo 11); não há
como extrair pixels crus deste firmware.

## 7. Módulos 3 (hw_auth), 4 (db_blob) e 11 (bio)

Resumo; detalhe instrução-a-instrução em `protocol/notes/mod3_4_11.md`.

### Módulo 3 — hw_auth (`0x3da4`): desafio e token de autorização

`cmd 1..6` (tabela `0x3dd2`), buffer mínimo `0x10`.

| cmd | efeito |
| --- | --- |
| 1 | `set_auth_challenge`: `+8` = u64 challenge (copiado para `ctx+0x08`) |
| 2 | `get_enrol_challenge`: sorteia 8 B (`fpc_secure_random`) em `+8` e guarda com o uptime |
| 3 | `authorize_enrol`: `+8` = tamanho ≥ `0x45`, token em `+0x0c`; valida HMAC e janela de ~10 min (`0x927c1` ms) |
| 4 | `get_auth_result`: devolve token de `0x45` B em `+0x0c` (versão 0, challenge, `secure_user_id`, `database_id`, `BE(2)`, `BE64(S+0xa8)`, HMAC-SHA256 de 37 B) |
| 5 | `init_hw_auth`: unwrap da chave AES de 32 B para `ctx+0x65`; decifra blob do **keymaster** (rótulo `keymaster64` conferido por `strncmp`) |
| 6 | não implementado (`0xE8A34063`) |

O token só valida se o challenge enviado (cmd 1) for **igual** ao sorteado
(cmd 2) — na prática: chamar cmd 2, devolver o valor no cmd 1 e só então usar o
token do cmd 4 no cmd 3.
A cifra do unwrap e o HMAC usam *veneers* para a tabela de syscalls do TEE,
fora da imagem: não há como reimplementar (nem é preciso — roda dentro do TEE).

### Módulo 4 — db_blob (`0x4048`): o banco de templates é um arquivo

`cmd 6..17` (tabela `0x4088`), buffer mínimo `0x70`.

| cmd | efeito |
| --- | --- |
| 6 | tamanho do blob empacotado → `+8` |
| 14 | abre transferência: `+0xc` = modo (0 = host lê, 1 = host escreve), `+0x10` = tamanho. Exige estado ocioso |
| 15 | reset/fecha e limpa o buffer |
| 16 | lê um chunk (TA → host): `+8` = pedido, dados em `+0x0c`; **retorno da função** = bytes restantes (0 = fim) |
| 17 | escreve um chunk (host → TA) + commit no último |

Formato do blob: `{u32 tamanho_plano, cabeçalho de 0x34 B, ciphertext}` —
overhead fixo de 52 B (`fpc_get_wrapped_size` = `len + 0x34`), teto
`0x1b5800` (1,79 MB), que é o tamanho dos dois buffers do módulo 11.
A criptografia (`fpc_wrap_crypto`/`fpc_unwrap_crypto`) roda no TEE: para nós o
blob é **opaco**, guardado como arquivo comum.

Fluxo do HAL (o que replicar): *store* = cmd 6 → cmd 14 modo 0 → laço cmd 16 →
`open(O_WRONLY|O_CREAT|O_TRUNC,0600)`+`write`+`fsync` → cmd 15;
*load* = `stat` (se não existe → cmd 7 `load_empty_db`) → cmd 14 modo 1 →
`read` → laço cmd 17 → cmd 15 (se o TA recusar com `-18`, o HAL apaga o arquivo
e recomeça vazio).

### Módulo 11 — bio (`0x420`): enrolar e verificar

`cmd 0..11` (`tbh` em `0x476`), buffer mínimo `0x70`; `cmd > 11` é rejeitado
(por isso `get_identify_statistics`, cmd 18 do HAL, sempre falha aqui).
`+0x08` é o campo in/out de tamanho/valor da resposta.

| cmd | efeito | saída |
| --- | --- | --- |
| 0 | `bio_init` | — |
| 1 | `begin_enrol` | — |
| 2 | `enrol` (uma amostra) | `+8` = amostras restantes |
| 3 | `end_enrol` (cria template) | `+8` = id32 do dedo |
| 4 | `identify` / `identify_image_status` | `+8` id32, `+0xc` coverage, `+0x10` quality, `+0x14/+0x18/+0x1c/+0x20` |
| 5 | `update_template` | `+8` 0/1 |
| 7 | `load_empty_db` | — |
| 8 | `get_finger_ids` | `+8` count (in = capacidade), `+0xc` u32[count] |
| 9 | `delete_template` (id32 em `+8`) | — |
| 10 | `set_gid` | — |
| 11 | `get_template_db_id` | `+0x10` u64 |

O *matching* é interno (`fpc_algo_identify`), com a imagem vinda do contexto
comum (`fpc_common_get_handle()+8`) — coerente com o módulo 10 cmd 5.
Máximo de templates fixo em **5** (`ctx+0x9c`).

## 8. Energia, reset e IRQ

| Sinal | Pino | Uso |
| --- | --- | --- |
| IRQ | GPIO90 (falling, pull-down) | `fpc_irq_wait` espera o dedo |
| reset | GPIO4 | pulso do helper antes do TA subir |
| enable 1,8 V | GPIO29 | alimenta o sensor (GPIO30 é do Chipone) |

No Android o helper expõe `/sys/class/fingerprint/fpc1020/{irq,irq_cnt,hw_reset,dev_enable}`.
No Linux o equivalente é gpiolib + evento de IRQ: nada precisa ser reimplementado
do kernel Android.

## 9. O que isso implica para o cliente Linux

Ordem mínima para um leitor funcional (captura + verificação dentro do TA):

1. energizar (GPIO29=1), reset (GPIO4) e soltar o sensor;
2. kernel: carregar `fpctzapp` no TEE e expor `start_app`/`send_modified_cmd`
   com a região externa em memória TZ (até ~1,8 MB para o blob);
3. userspace: `{12,1}` para confirmar o build; `{10,7}` para ler o OTP;
4. `{10,0,1,2,3,4,5}` no ciclo de captura (buffer mínimo `0x70`);
5. módulo 4 para guardar/carregar o blob de templates num arquivo do Linux
   (o blob é opaco: a cifra roda no TEE);
6. módulo 11: `begin_enrol`(1) → `enrol`(2) por amostra → `end_enrol`(3) para
   cadastrar; `identify`(4) para verificar (o matching é interno ao TA).

**Ponto aberto que decide o esforço:** o cadastro pode exigir token de
autorização (módulo 3). O token vem de `get_auth_result` e a chave para decifrar
o blob inicial vem de `init_hw_auth`, que faz unwrap de um blob do **keymaster**
(outro TA, `keymaster64`). Se o TA recusar `enrol` sem token, precisaremos
também do caminho do keymaster — e aí a pergunta de armazenamento seguro volta
(a chave mestra do KM vive no TEE/RPMB). Só um teste controlado responde; nada
disso foi executado.

Não existe caminho para pixels crus (seção 6): o leitor funciona, mas depurar
"o que o sensor viu" exigiria RE do driver de sensor dentro do TA.

Continua **não** necessário: partição `ssd`, listeners do `qseecomd`,
enrollment DB do Android, ou habilitar o SPI1 da AP (o SPI é feito dentro do TEE).

## 10. Desconhecidos

- se `enrol` exige token (módulo 3) e, portanto, o keymaster;
- semântica de `frame+0x14` e `+0x1c` na resposta do `identify`, e do `BE(2)` /
  `BE64(S+0xa8)` do token;
- conteúdo/semântica exata de `frame+0x10` no cmd 5 (status vs. contador);
- layout do OTP devolvido em cmd 7 (o decoder `otp_*` está no TA; para identificar
  o silício teríamos de reimplementar ou extrair o blob bruto);
- por que o host reescreve `test id 1 → 7` (consequência medida: checkerboard do
  TA inalcançável);
- geometria/formato da imagem uncalibrated (atrás de `sensor_driver_capture_image`);
- se o TEE aceita `QSEOS_APP_START_COMMAND` para `fpctzapp` vindo do Linux —
  só um boot de teste responde, e isso segue não autorizado.
