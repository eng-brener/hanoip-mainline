# TA de digital (fpctzapp): por que o cadastro exige HAT

Análise estática, offline, do aplicativo seguro do leitor de digitais deste
aparelho. Nada foi executado no telefone, nenhum comando QSEECOM foi enviado e
nenhuma partição foi lida ou escrita nesta etapa.

## Artefatos

| arquivo | SHA-256 |
| --- | --- |
| `fpctzapp.mdt` | `ad676d9d5e69f5a98d713debb5e6c886db37e84ecc6b5a803ea53281c6b4b9a1` |
| `fpctzapp.b02` (segmento de código) | `c90e444a64cbefe080d4404e3fc9058d10eab834361db9037fc67a70813dffab` |
| `fpctzapp.elf` (reconstruído) | `a17a0ca02747f1741dd00960601ec3408ba1ca73fc8795a66e5df6e0dc96bc17` |
| HAL `android.hardware.biometrics.fingerprint@2.1-service-fpc` | `107a3352758e687d4608aa0256b77ac30e74cba9e1db5d866d015bc28c07b1d8` |

O HAL tem o mesmo hash do artefato já analisado em `../keymaster-lookup/NOTAS.md`,
o que confirma que é o mesmo binário.

O dump `firmware.tar` traz o app TEE em `vendor/firmware_mnt/image/fpctzapp.b00`
até `.b07` mais `.mdt`, no formato Qualcomm. `rebuild.py` remonta o ELF:
cabeçalho do `.mdt` (primeiros 0x1000 bytes), `b01` em 0x1000, `b02` em 0x3000
(código, vaddr 0), `b03` em 0x117138, `b04` em 0x117250, `b05` em 0x2cfdf4 e
`b07` em 0x2d0178. O `readelf` passa a aceitar o arquivo e os cabeçalhos de
programa batem com os tamanhos dos segmentos. A numeração de VA usada abaixo é
a do ELF reconstruído; `file_off = vaddr + 0x3000` na região de código.

## O TA não guarda as digitais: ele devolve blobs cifrados

Os únicos imports de armazenamento são `qsee_fts_encrypt`,
`qsee_fts_decrypt`, `qsee_fts_integrity_protect` e `qsee_fts_integrity_verify`.
Não há `qsee_sfs_*`, `qsee_stor_*`, `qsee_fopen` nem acesso a partição. O módulo
4 (`fpc_ta_db_blob_module`) devolve o banco cifrado para o mundo normal.

No Android, quem grava é o HAL: as únicas rotas de dados no binário do HAL são
`/data/fpc_tpl/`, `/data/fpc/` e `/data/vendor/.fps/`. Ou seja, **os templates
são arquivos comuns em userspace**, protegidos pelo FTS do TEE, e não registros
em RPMB. Num Kali cabe a nós escolher onde esse arquivo fica.

## Módulos e comandos observados

Descritores de módulo (16 bytes, em 0x116000; campo `[8]` = despachante, campo
`[12]` = id): comum 12, bio 11, sensor 10, hw_auth 3, db_blob 4, sensortest 5,
navigation 8. O módulo 3 (`hw_auth`) despacha em `0x3da4` e aceita comandos
1..6 (`tbb` em 0x6dce); entre eles:

* `0x6dd8` grava o desafio de 8 bytes em `ctx+0x8` e chama um helper;
* `0x6df6` zera `ctx+0x10`, sorteia valores até obter desafio não nulo, grava o
  uptime em `ctx+0x18` e copia `ctx+0x10`;
* `0x6e2e`/`0x6e3a` exigem entrada de pelo menos 69 bytes e copiam para
  `ctx+0x20` (o token de autenticação);
* `0x6e46` chama `fpc_ta_hw_auth_unwrap_key` (`0x4005`) e, se der certo, marca
  `ctx+0x88 = 1`.

`ctx+0x65` guarda a chave HMAC de 32 bytes depois do desempacotamento;
`fpc_unwrap_crypto` (`0x3a05`) usa `qsee_decapsulate_inter_app_message` para
abrir a mensagem encapsulada que o Keymaster devolve no comando `0x205`.

## A verificação que derrubou o nosso `end_enrol`

`fpc_check_token_integrity` (`0x3c01`, arquivo 0x6c00):

1. exige `token[0] == 0`, senão `0xe8a3403b`;
2. exige `ctx+0x88 != 0` (chave presente), senão `0xe9134040`;
3. calcula `fpc_hmac_sha256(chave = ctx+0x65, 32 bytes, dados = token, 37 bytes)`
   e compara com `token+37` (32 bytes), senão `0xe8a34055`.

Isto é: o token tem 69 bytes, `version(1) + challenge(8) + user_id(8) +
authenticator_id(8) + type(4) + timestamp(8) = 37` e depois um HMAC-SHA256 de
32 bytes. **O HMAC é conferido com a chave real do Keymaster dentro do TEE.**

`fpc_check_enrollment_allowance` (`0x3c61`, arquivo 0x6c60) chama `0x6cb0`
antes de devolver o limite de cadastros:

* `ctx+0x88 == 0` → `0xe913406f` (exatamente o erro que o nosso `end_enrol`
  devolveu em 2026-10-29, o que liga o caminho de cadastro a esta checagem);
* desafio ausente → `0xe9134074`;
* `ctx+0x10..0x17` diferente de `token[1..8]` → `0xe8a34079`;
* token guardado há mais de ~600 s (0x927c1 no relógio do TEE) → `0xe8c34083`,
  e o desafio é apagado;
* por fim valida o HMAC acima.

Esse `fpc_check_enrollment_allowance` é chamado de forma incondicional no
caminho de cadastro (chamada em 0x35fe, logo antes do `fpc_algo_begin_enroll`
e da manipulação da contagem em `ctx+0x64`).

## Consequência prática

Não dá para fabricar HAT: o HMAC depende de uma chave de 32 bytes que só existe
em claro dentro do TEE. Conseguir a chave encapsulada pelo Keymaster (`0x205`)
serve apenas para o TA desempacotá-la; ela não volta para o mundo normal.

O único jeito legítimo de gerar um HAT é um backend que assine com essa chave,
ou seja o Gatekeeper do próprio aparelho após verificar uma credencial
(`0x21001` cadastrar e `0x21002` verificar). Isso escreve no estado de
credenciais TEE que o Android também usa, e ainda não se sabe se esse estado
vive na partição lógica RPMB `0x474b3232` ou no arquivo `gk_sfs_file`. Ver
`../gatekeeper-offline/RESULTADO.md`.

## O que continua desconhecido

* Backend ativo do Gatekeeper (RPMB lógico ou SFS): não observado.
* Se o Gatekeeper deste aparelho já tem credencial cadastrada: não verificado,
  e verificar exigiria enviar comandos.
* Comportamento de um cadastro real do Gatekeeper (rechaveamento, criação de
  partição, efeitos sobre o PIN do Android): não testado e não presumido.

## Ferramentas locais

`rebuild.py` remonta o ELF; `symbols.txt` é a tabela dinâmica completa (1940
símbolos, muitos nomes FPC preservados); `symat.py` resolve endereço → símbolo;
`disasm.txt` é a desmontagem Thumb de todo o segmento de código; `range_calls.py`
lista alvos de `bl`/`b` num intervalo.

Nada aqui foi executado no aparelho.
