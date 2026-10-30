# Módulo 5 (sensortest) do TA FPC do Moto G60 — decodificação estática

Escopo: análise **estática e offline** do TA `fpctzapp-reconstructed.elf`, do HAL
`fingerprint-service-fpc` e do utilitário de fábrica `fpc_tee_test`. Nada foi
executado, nada foi enviado ao aparelho, nenhuma partição foi tocada. JSON
estruturado: `mod5_sensortest.json` (mesma pasta).

Convenções: **OBSERVADO** = instruções/bytes lidos no binário (endereço citado);
**INFERIDO** = conclusão a partir do observado; **DESCONHECIDO** = não provado.

---

## 1. Entrada do módulo e tabela de despacho

Roteador: `fpc_ta_route_command` @ `0x1a8`. Ele casa `[buf+0]` (module id) contra
uma tabela de descritores em `0x116000` (literal em `0x244` + `pc` = `0x1e0`).
O descritor do módulo 5 está em **`0x1160c0`**: `+0x0` init = 0, `+0x4` exit = 0,
**`+0x8` handler = `0x4325`** (= `0x4324`, Thumb), `+0xc` module id = **5**.
O handler é chamado como `handler(buf, len, cmd_id)` (`0x230`: `r2 = [buf+4]`).

Prólogo do handler (`0x4324`):

| Endereço | Instrução | Efeito |
|---|---|---|
| `0x432e/0x4334` | `movw r5,#0xc0a1 ; movt r5,#0xe8a1` | `r5 = 0xe8a1c0a1` (erro de argumento) |
| `0x433c` | `cmp.w r9,#0 ; beq 0x4412` | `buf == NULL` → devolve `0xe8a1c0a1` |
| `0x4344` | `cmp r1,#0x34 ; blo 0x4412` | **`len < 0x34` (52) → `0xe8a1c0a1`** — única checagem de tamanho, vale para todos os cmds |
| `0x434a` | `bl 0x11208` | `fpc_sensor_communication_start()` |
| `0x4356` | `bl 0x248` | `fpc_common_get_handle()` → `r8` |
| `0x435c` | `add.w r4,r5,#0x2d` | `r4 = 0xe8a1c0ce` ("cmd não suportado") |
| `0x4360` | `bl 0xc94` | `fpc_sensor_get_handle()` → `r0` (1º arg de toda função de teste) |
| `0x4364` | `cmp r6,#6 ; bhi 0x4408` | **cmds válidos: 0..6** |
| `0x436a` | `tbb [pc,r6]` | tabela em `0x436e` |
| `0x4408` | `bl 0x1127c` | epílogo único: `fpc_sensor_communication_stop()`, devolve `r4` |

Tabela `0x436e` = bytes `04 09 0e 13 27 4d 48`; alvo = `0x436e + 2*byte`:

```
cmd 0 -> 0x4376   cmd 1 -> 0x4380   cmd 2 -> 0x438a   cmd 3 -> 0x4394
cmd 4 -> 0x43bc   cmd 5 -> 0x4408   cmd 6 -> 0x43fe
```

`cmd 5` aponta para o epílogo com `r4 = 0xe8a1c0ce` ⇒ **buraco/não implementado**
(e o HAL nunca envia cmd 5: não existe constante `{5,5}` na .rodata dele).

---

## 2. Uma linha por comando

Todos exigem `len >= 0x34`; resposta sempre no próprio buffer compartilhado.

| cmd | handler | função do TA chamada (nome exportado) | lê | escreve | retorno TA |
|---|---|---|---|---|---|
| 0 | `0x4376` | `fpc_test_self_test_init` (`0x1cb30`) | — | `+0x2c` = u32 status (= conteúdo do reg `0x1C` do sensor, ou 1 em erro) | status do driver |
| 1 | `0x4380` | `fpc_test_run_self_test` (`0x1c8fc`) | `+0x2c` (pin/status corrente) | `+0x2c` = 0 (pass) / 5 / 6 / `0x10` | status do driver |
| 2 | `0x438a` | `fpc_test_self_test_cleanup` (`0x1cbe8`) | `+0x2c` | `+0x2c` | status do driver |
| 3 | `0x4394` | `fpc_test_is_*_supported` (13 entradas) | `+0x8` = test id (0..12; `>12` → retorna 0) | **nada** — a resposta é o próprio código de retorno (1 = suportado) | 0/1 |
| 4 | `0x43bc` | 9 testes (tabela abaixo) | `+0x8` = test type (1..9; fora → `-15`), `+0x0c..+0x27` = bloco de 28 bytes | `+0x0c..+0x27` de volta, `+0x28` = resultado/qualidade, `+0x2c` = status, `+0x30` = tamanho do log | status do teste |
| 5 | `0x4408` | — (não implementado) | — | — | `0xe8a1c0ce` |
| 6 | `0x43fe` | `fpc_device_capture_uncalibrated_image` (`0x108e0`) | **nada além do header** | **nada** | status da captura |
| 7 | — | **não despachado neste TA** (o HAL usa `{5,7}` para `get_log`) | (`+0x8` = tamanho pedido, do lado host) | (`+0x8` tamanho, `+0xc` dados, do lado host) | `0xe8a1c0ce` |

### cmd 4 — tabela `0x43e6` (bytes `05 1e 23 27 2c 30 41 45 49`)

| type | handler | função | args além de `(sensor)` |
|---|---|---|---|
| 1 | `0x43f0` | `fpc_test_run_checkerboard_test` `0x1baa4` | `(ctx, &buf[0x2c])` |
| 2 | `0x4422` | `fpc_test_run_image_quality_test` `0x1c324` | `(ctx, &buf[0x2c], &buf[0x28])` |
| 3 | `0x442c` | `fpc_test_run_reset_pixel_test` `0x1c3ec` | `(ctx, &buf[0x2c])` |
| 4 | `0x4434` | `fpc_test_run_afd_test` `0x1ae1c` | `(0, &buf[0x2c])` |
| 5 | `0x443e` | `fpc_test_afd_cal_test` `0x1b2e0` | `(ctx, &buf[0x2c])` |
| 6 | `0x4446` | `fpc_test_run_module_quality_test` `0x1b804` | 6 u32 de `+0x0c..+0x20` + ponteiros `&buf[0x24]`, `&buf[0x28]`, `&buf[0x2c]` |
| 7 | `0x4468` | `fpc_test_defective_pixels_test` `0x1c584` | `(ctx, &buf[0x2c])` |
| 8 | `0x4470` | `fpc_test_otp_validation` `0x1c870` | `(ctx, &buf[0x2c])` |
| 9 | `0x4478` | `fpc_test_txpulse_checkerboard_test` `0x1c780` | `(ctx, &buf[0x2c])` |

`ctx` = `*(fpc_common_get_handle()+8)` (`0x43ce ldr r1,[r5,#8]`) — o mesmo objeto
que `fpc_device_capture_uncalibrated_image` recebe como 2º argumento. Antes do
despacho o handler grava `buf+0x28 = 0` (`0x43d0`) e `buf+0x2c = 1` (`0x43d8`).
Depois do teste: `0x4480 bl 0x1c868 (fpc_test_get_log_size) ; str.w r0,[r9,#0x30]`.

### cmd 3 — tabela `0x43a8` (bytes `30 73 76 79 7c 80 83 86 30 89 07 07 07`)

ids 1..7 e 9 → `fpc_test_is_checkerboard_test_supported`,
`..._image_quality_...`, `..._reset_pixel_...`, `fpc_test_is_afd_test_supported(0)`,
`..._afd_cal_...`, `..._module_quality_...`, `..._defective_pixels_...`,
`..._txpulse_checkerboard_...`; **ids 10, 11, 12 → `fpc_test_is_check_esd_supported`**;
**ids 0 e 8 não têm função e caem no epílogo devolvendo 1** (o preset de `0x43a2`).

---

## 3. Frame (o que o HAL escreve e o TA lê)

```
+0x00 u32 module_id = 5            (TAC)
+0x04 u32 cmd_id   = 0..6          (TAC -> 0x4338 r6)
+0x08 u32 arg0  : test id (cmd3/cmd4) | tamanho in/out (cmd7)
+0x0c u32[7]  : bloco de parâmetros do teste (28 bytes, cmd4, in/out)
+0x28 u32     : resultado/qualidade (cmd4; preset 0)
+0x2c u32     : status / valor de pino IRQ (cmd0 out, cmd1 in/out, cmd2, cmd4 out)
+0x30 u32     : tamanho do log em bytes (cmd4)
+0x34         : tamanho mínimo total aceito pelo TA (0x4344) — igual ao "+0x34"
                que fpc_tee_sensortest_get_log usa em alloc(*len+0x34) (0x20564)
```

Fora do escopo: como o TAC preenche o `len` que o roteador repassa — `fpc_tac_transfer`
(`0x22df0`) põe `[shared+0x10]` no descritor QSEECom (`0x22e38`) com tamanhos fixos
`0x40/0x40` (camada TAC, não decodificada aqui).

Erros do módulo: `0xe8a1c0a1` (buf nulo / curto), `0xe8a1c0ce` (cmd 5 ou >6),
`0xfffffff1` = −15 (test type inválido no cmd 4).

---

## 4. `fpc_tee_sensortest_run_test` (HAL `0x1ffd8..0x204b4`)

Assinatura observada: `int (void *ctx, uint32_t test_id, uint32_t delay_ms,
void *params_inout /*28B*/, uint32_t *out_result, uint32_t *inout_status,
uint32_t *out_log_size)` — args mapeados em `0x20000/0x20018/0x20038/0x20034`,
`*out_log_size = 0` em `0x20054`.

Pré-processamento:
* `0x20044-0x2004c`: **`test_id == 1 → 7`** (`csel w27,w8(=7),w21,eq`).
* `0x20050-0x20058`: se `id == 6`, `fpc_tee_check_finger_lost(ctx)` (`0x215c4`) antes.
* `0x20064-0x200a8`: se `delay_ms != 0`, `fpc_tee_wait_finger_down(ctx)` (`0x21588`)
  e `usleep(delay_ms*1000)`.
* `0x200ac-0x200bc`: `id == 7` (ou 1, morto) → `0x201ec`; `id == 0` → self test; resto → geral.

**Caminho geral (`0x201f8`)** — é o comando de teste propriamente dito:
`buf` zerado (0x40), `buf+0x30 = 0`, `buf[0..8] = {5,4}` (`0x20228`, const `0xe1d0`),
`buf+0x8 = id` (`0x20240`), 28 bytes de parâmetros copiados para `+0xc` (`0x20244-0x20250`),
`fpc_tac_transfer` (`0x20258`); na volta os parâmetros são copiados de volta e
`*out_result = buf+0x28` (`0x2026c`), `*inout_status = buf+0x2c` (`0x20274`),
`*out_log_size = buf+0x30` (`0x2027c`). Retorno = status do transfer (`0x20290`
salta direto para o epílogo, `w0` é o resultado do transfer).

**Caminho id 0 = Self Test** (`0x200c0` → `0x202f0` → …):
1. `{5,0}` (init) → `0x20130`; guarda `buf+0x2c`; erro → log
   `FPC_TA_SENSORTEST_SELF_TEST_INIT failed! Status = %d` (`0xa404`), retorna 7.
2. `fpc_tee_status_irq` (`0x21470`): `<0` → `IRQ TEST READ INITIAL -> FPC_ERROR_SENSOR`
   (`0xd6e4`); `==0` → `... FPC_SELFTEST_IRQ_FAIL pin = %d should be 0` (`0xd99d`),
   `*inout_status = 6` e vai para o cleanup.
3. `{5,1}` (run) com `+0x2c` = valor corrente → `0x2039c`; se `buf+0x2c|status != 0`
   → `Selftest failed status = %d result = %d` (`0xd711`).
4. `status_irq`: `<0` → `IRQ TEST READ AFTER -> FPC_ERROR_SENSOR` (`0xd176`); `==0`
   repete o passo 3; `>0` → `fpc_tee_sensortest_test_command(ctx, 2, &buf+0x2c)`
   (cleanup, `0x203f8`); erro → `FPC_TA_SENSORTEST_SELF_TEST_CLEANUP failed` (`0xb343`), retorna 7.
5. `status_irq`: `<0` → `IRQ TEST READ END -> FPC_ERROR_SENSOR` (`0xc3a`); `>0` →
   `... pin = %d should be 0` (`0xae39`) e repete o cleanup; `==0` → `readHardwareID`
   (`0x20690`) e retorna 0.

Ou seja: **init → poll IRQ → run (READ INITIAL/AFTER) → poll → cleanup → poll → readHardwareID**.
O "log" desse teste vai para o log interno do TA; o HAL só recebe o **tamanho** (`buf+0x30`).

---

## 5. `capture_uncalibrated` (`0x204b4`) e `get_log` (`0x2050c`)

`fpc_tee_sensortest_capture_uncalibrated(ctx)` (`0x204b4`, 88 B): loga com
`__func__ = 'fpc_tee_sensortest_capture_uncalibrated'` (`0x9f17`), grava
`d0 = {5,6}` (`0xe150`) em `[buf]` (`0x204fc`) e **faz tail-call** para
`fpc_tac_transfer` (`0x20508`). Nada mais: **sem offset, tamanho, largura, altura
ou formato no frame**.

Para onde vai a imagem (OBSERVADO): `0x43fe ldr.w r1,[r8,#8]` + `0x4402 bl 0x108e0`
`fpc_device_capture_uncalibrated_image(dev, ctx)` →
`0x108ec r0 = [dev+0xec]`; `0x108fc fpc_sensor_driver_capture_image(driver, 0x10, 0, ctx, 0)`
→ `0x17a30`: o 5º argumento (`r3`) é o **sink** e é repassado a
`sensor_driver_capture_image` (`0x17a4e/0x17a52`). Depois: `fpc_sensor_deep_sleep`
(`0x1090a` → `set_mode(driver,3)` em `0x10968`). Conclusão (INFERIDO): a imagem fica
no objeto de contexto do TA (o ponteiro de `fpc_common_get_handle()+8`), consumida
dentro do TA; **não é marshallada de volta pelo módulo 5**. Do lado host,
`do_capture` (`0x1ba90`) só converte o status em callback (`0x1bac0` testa
`[ctx+0x249]`; status entregue a `[ctx+0x258]([ctx+0x250], status)` em `0x1bb20`/`0x1bb88`).

`fpc_tee_sensortest_get_log(ctx, &len, dst)` (`0x2050c`, 252 B):
`0x2054c fpc_tee_engineering_enabled` (senão **−15**), `0x20564 alloc(*len + 0x34)`,
`0x20578 {5,7}`, `0x2058c str *len → buf+8`, transfer, `*len = buf+8` e
`0x205d0 memcpy(dst, buf+0xc, size)`; se `dst == NULL` ou `*len < retornado` →
`*len = 0` e **−10** (`0x205b4/0x205b8`).

**Divergência importante (OBSERVADO × INFERIDO):** o HAL usa `{5,7}`, mas este TA
só aceita module 5 cmds **0..6** (`0x4364`). Além disso `fpc_test_get_log_size`
(`0x1c868`) tem **um único chamador** (`0x4480`, dentro do cmd 4) e
`fpc_test_get_log` (`0x1c86c` → `fpc_sensortest_ctl_get_log` `0x1b508`) **não tem
chamador nenhum** em todo o texto do TA. Consequência (INFERIDA): `get_log` falha
com `0xe8a1c0ce` neste TA e o conteúdo do log é inalcançável; só o tamanho
(`cmd 4`, `+0x30`) está disponível.

---

## 6. Enum de testes do host (a verdade sobre os ids)

Não há enum em símbolo; a tabela **`fpc_sensortest_tests` em `0x27940`** (13 entradas
de 48 bytes `{u32 id, pad, char *name @+8, char *description @+0x10, char *stamp @+0x18}`)
foi recuperada via `.rela.dyn` e é consumida por `get_sensor_tests` (`0x1b098`,
laço `0x270/0x30 = 13`, uma chamada a `is_test_supported` por id):

`0 Self Test` · `1 Checkerboard Test` · `2 Image Quality Test` · `3 Image Reset Pixel Test` ·
`4 AFD Calibration Test` · `5 AFD Cal Test` · `6 Module Quality Test` ·
`7 Defective Pixels Test` · `8 OTP Validation Test` · `9 TXPulse Checkerboard Test` ·
`10/11/12 ESD Check Pre/Check/Post` · `13` vazia.

`enroll_no_sensor` e `authentication_no_sensor` **não estão nessa tabela** — não são
comandos do módulo 5 (ver §7).

---

## 7. `fpc_tee_test` (utilitário de fábrica)

`main` em `0x5048`; `getopt_long` em `0x51fc`; string curta `sbqcpueEadACrRD`
em `0x20de`; opções longas em `0xd5c0` (12 × 32 B, `val` em `+0x18`, ponteiros de
nome recuperados de `.rela.dyn`); tabela de saltos em `0x18c0`
(alvo = `0x5184 + 4*byte[char+1]`); `%s usage:` em `0x21a5`. `-h/-V/-r/-R` e
qualquer outra opção caem em `0x54c8` → `Non handled option '%c'. Close down` (`0x33fe`).

| opção | bloco | banner | chamada | id |
|---|---|---|---|---|
| `-s` `--sensor_test` | `0x546c` | `Starting sensor_test` (`0x20ee`) | `0x895c` run_test | **0** |
| `-b` `--checkerboard_test` | `0x53f4` | `Starting checkerboard_test` (`0x1f3a`) | `0x895c` | **1 → o TA recebe 7** |
| `-q` `--imagequality_test` | `0x5184` | `Starting imagequality_test` (`0x24be`) | `0x895c` | **2** (delay 500 ms, `0x51c0`) |
| `-p` `--resetpixel_test` | `0x5398` | `Starting resetpixel_test` (`0x3537`) | `0x895c` | **3** |
| `-u` `--capture_uncalibrated` | `0x5538` | `Starting capture_uncalibrated` (`0x2018`) | `0x8e38` = capture (cmd 6) | — |
| `-C` `--afd_calibration_test` | `0x52e0` | `Starting afd_calibration_test` (`0x2b91`) | `0x895c` | **4** |
| `-D` `--defective_pixels_test` | `0x533c` | `Starting defective_pixels_test` (`0x2a9a`) | `0x895c` | **7** |
| `-E` `--enroll_no_sensor_test` | `0x5258` | `Starting enroll_no_sensor test` (`0x37ea`) | `0x55d8`+`0x5a10` | — |
| `-A` `--authentication_no_sensor_test` | `0x5220` | `Starting authentication_no_sensor test` (`0x1bfa`) | `0x55d8`+`0x5a10` | — |
| `-e` `--enroll_test` | `0x52b8` | `Starting enroll_test` (`0x2342`) | `0x55d8`+`0x5a10` | — |
| `-a` `--authentication_test` | `0x527c` | `Starting authentication_test` (`0x351a`) | `0x55d8`+`0x5a10` | — |
| `-d` `--db_blob_test` | `0x5450` | `Starting db blob test` (`0x3809`) | `0x5e30` | — |

O utilitário carrega **cópias estáticas** das mesmas funções do HAL: run_test em
`0x895c` (1244 B, idêntico a `0x1ffd8`, inclusive o reescrita `1→7` em
`0x89c8-0x89d0`), capture_uncalibrated em `0x8e38`, test_command em `0x8e90`.
**Não existe cópia de `get_log`** (nenhuma string `fpc_tee_sensortest_get_log`, nenhum
`alloc(len+0x34)`, nenhum `memcpy` de `+0xc`).

Depois de cada teste o utilitário imprime `printf("%s: %d", <nome>, status_de_buf+0x2c)`
(formato `0x3013`; ex. `0x531c-0x5334`).

**Arquivo de imagem:** não existe. Não há string de extensão de imagem
(`.pgm/.raw/.bmp/.png`) e o bloco `-u` só imprime status + `End of test.`
(`0x5568`). Os únicos arquivos que o binário grava são banco de templates
(`/data/system/test.db`, `%s Successfully wrote template database %s`), db blobs e
CSVs de KPI em `/data/fpc/diag_logs` com o padrão
`%s/oddc_%s%s_%04d%02d%02d%02d%02d%02d_%s_#%s#.csv` (`0x2d3f`). `img.id` (`0x25f8`)
é **rótulo de coluna de CSV** (argumento de `fprintf` em `0x8254`), não nome de arquivo.

`-E`/`-A` (`0x55d8`) não usam o módulo 5: abrem um diretório (`0x5638 opendir`) e
injetam imagens via `fpc_tee_debug_inject` (referência em `0x7410`), com os diretórios
`/data/system/enroll/` e `/data/system/verify/`. O fluxo completo de
`0x55d8`/`0x5a10` (enrol/identify) não foi decodificado — fora do escopo do módulo 5.

---

## 8. Unknowns

1. Nomes reais do módulo 5 e dos comandos dentro do TA (sem símbolos; tudo aqui é
   `name_guess` derivado de strings do HAL/utilitário).
2. **Por que o host reescreve `test id 1 → 7`** (parece shim de compatibilidade com
   numeração antiga). Consequência observável: `-b/checkerboard` executa no TA
   `fpc_test_defective_pixels_test`, e o tipo 1 do TA (`fpc_test_run_checkerboard_test`)
   é inalcançável por essas APIs. O branch `if (w27 == 1)` em `0x200b4` é código morto.
3. Se algum outro build de TA despacha `cmd 7` (`get_log`) com o layout `+8` tamanho /
   `+0xc` dados. Neste build, não.
4. Significado exato do `len` que o TAC repassa ao handler (camada TAC:
   `fpc_tac_transfer` `0x22df0`, tamanhos fixos `0x40/0x40`).
5. Significado dos 7 u32 do bloco de parâmetros do cmd 4 por tipo de teste (só o
   consumo dos campos foi medido).
6. Geometria/formato da imagem uncalibrated (atrás de `sensor_driver_capture_image`
   `0x16764` / `fpc_sensor_driver_get_default_capture_config` `0x17a70`); o módulo 5
   não carrega nada disso.
7. Semântica dos literais de erro `0xe8a1c0a1` / `0xe8a1c0ce` (nenhuma string de nome).
