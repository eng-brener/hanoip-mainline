# Autorização do cadastro: achados 29/10

## Observado no Kali

Consulta de nome via `qcom_scm_qseecom_app_get_id("keymaster64")` devolveu
status 0, app_id 1. O módulo `lookup.ko` apenas consulta o ID; não envia
comandos ao app nem lê chaves. App_id é volátil e não deve ser fixado.
`keymaster64.mdt` não foi encontrado na montagem de firmware examinada; a
consulta prova apenas que o nome é resolvido nesta sessão, não como foi carregado.

## Análise estática do HAL original

Artefato SHA-256 `107a3352758e687d4608aa0256b77ac30e74cba9e1db5d866d015bc28c07b1d8`.
REA `ev_c922714e5d19cd8373d322ea79c67c397184a5c89174a49644ae2b22855c2067`:
`fpc_tee_init_hw_auth` abre keymaster64, envia requisição normal de 64 bytes
cujo primeiro par u32 é {0x205, 2}; resposta de 0x3c0 bytes contém status u32
em +0, offset u32 em +4 e comprimento u32 em +8, sendo offset relativo ao
início da resposta. Copia o blob encapsulado para frame FPC {3,5}, tamanho em
+8 e bytes em +0xc. Os limites do offset e tamanho precisam ser validados no
cliente e o blob não deve ser impresso ou persistido.

REA `ev_67cd30a094e60279741fcc06a8c7f6ab370e2ea55d9e52b7accd729e9efebf6e`:
o HAL inicializa hw_auth ao abrir, após sensor e biometria.
REA `ev_3bea3912cc455f04dc63eefb154dcf69b5eaebeb48742a78ccf2729f6ec0a62f`,
`ev_72e588f4fbd14f7d84dde3d86540e0793ce55627f496f45adba75b071b9d7dab`,
`ev_fc8dc924f8009d40f740eeb620afcf0b8a24982aa3bdfbac3587cd879b087fe9`:
o HAL gera desafio com FPC, recebe do framework Android token HAT de 69 bytes
e o autoriza no FPC antes de iniciar a coleta. O HAT deve vir de uma verificação
legítima de credencial via Gatekeeper, não ser fabricado ou registrado em logs.

## Limites e segurança

O teste ainda não enviou nenhum comando para keymaster64 ou Gatekeeper e não
estabeleceu se o comando 0x205 consulta ou modifica armazenamento seguro.
Não há serviço Gatekeeper/Keymaster Android visível no Kali. É necessário
reconstruir o transporte de chamada normal com limites e verificar o ciclo de
vida e eventuais escritas seguras antes de qualquer execução. Mesmo que a chave
seja inicializada, falta gerar HAT válido legitimamente; não acessar bancos de
credenciais nem alterar/formatar nenhuma partição. Não há template persistido.

## Preparação offline

`km-response.h` e `test-km-response.c` implementam e testam, apenas com dados
sintéticos, uma leitura limitada do cabeçalho: status, offset relativo e tamanho;
rejeitam tamanho zero, sobreposição do cabeçalho, truncamento e overflow. Teste
local com AddressSanitizer e UndefinedBehaviorSanitizer passou. A hipótese de
offset mínimo 12 é uma escolha conservadora, não uma propriedade confirmada do
protocolo. O código não chama Keymaster e não grava nem exibe blobs.

O `qcom_scm_qseecom_app_send()` upstream exige buffers de qcom_tzmem e verifica
`res.result`; o helper experimental `qcom_scm_qseecom_app_send_phys()` utiliza
DMA físico e devolve o resultado SCM separadamente. Não é correto tratá-los como
intercambiáveis sem conferir contrato e tratamento de listeners/respostas.

Auditoria adicional: no código Motorola, `qseecom.c:3726-3738` encaminha
`QSEOS_RESULT_INCOMPLETE` a um listener e rejeita resultados não suportados. O
kernel upstream define SCM success=0, incomplete=1 e blocked-on-listener=2;
seu wrapper atual alerta, mas não processa listeners. Os dois helpers experimentais
anteriormente devolviam sucesso independentemente de `res.result`. Em
`kernel/src/scm_qseecom_app.frag.c` foram corrigidos localmente para rejeitar
incomplete/blocked com `-EOPNOTSUPP` e outros resultados de falha com `-EIO`.
A árvore compila (`BUILD_OK`, release `7.3.0-sm7150`); o kernel corrigido não
foi empacotado, inicializado ou testado no telefone. Não resolve listeners; se
eles ocorrerem, é necessário um serviço apropriado e auditoria do destino.
Os artefatos anteriores foram preservados em `kernel/out-before-scm-fix/`.

### Listener e risco de armazenamento (investigação adicional)

No driver Motorola `qseecom.c:1965-1995`, resultado INCOMPLETE fornece o ID
do listener em `resp.data`; o driver acorda o serviço registrado e em
`qseecom.c:2093-2134` envia resposta de sucesso ou falha ao TEE, repetindo
até o comando terminar. Se o serviço não existe, envia resposta de falha;
simplesmente retornar `-EOPNOTSUPP` ao cliente não conclui necessariamente a
operação segura nem prova que o TA deixou de usar os buffers. O wrapper
experimental não implementa retomada, cancelamento ou resposta de falha.
Portanto a correção de status impede falso sucesso mas NÃO é um mecanismo
completo de recuperação; não executar Keymaster com ela nem liberar/reutilizar
buffers após um possível INCOMPLETE até o ciclo de vida ser resolvido.

O mesmo código Motorola define RPMB_SERVICE=0x2000 e SSD_SERVICE=0x3000 e
trata ambos explicitamente (`qseecom.c:89-90,2099-2102`). O projeto público
https://github.com/wrobelda/qsee-supplicant documenta FS=10, time=11,
RPMB=8192 e GPFS=28672; seus serviços FS/GPFS podem escrever em disco e RPMB
não é implementado. Ele requer outro driver QSEECOM TEE, não o `/dev/tee0`
qcomtee atualmente encontrado. A identificação de listener ainda não prova que
keymaster64 ou este comando utilizem um deles. Não instalar ou iniciar o
supplicant, nem servir pedidos de escrita, no aparelho sob a regra vigente.

Segundo a documentação AOSP Gatekeeper, a verificação de credenciais tem
throttling, e a proteção contra tentativas repetidas pode envolver estado
persistente; logo não se deve iniciar verificações especulativas nem supor
ausência de escrita: https://source.android.com/docs/security/features/authentication/gatekeeper

## Identificação do local — resultado parcial

O descriptor UFS salvo em `work/ufs-100-20261025/descriptors.txt:111` contém
`rpmb_rw_size=0x40`; isso é evidência de um campo RPMB no dispositivo, não
demonstra provisionamento, nem que o contador Gatekeeper esteja nele. O driver
Motorola tem listener RPMB 0x2000 e SSD 0x3000, mas o uso por Gatekeeper não
foi observado. Qualcomm descreve RPMB como região física UFS/eMMC distinta:
https://docs.qualcomm.com/doc/80-70014-11/topic/secure-file-system.html
AOSP recomenda armazenamento seguro e admite RPMB; não garante o backend
particular deste aparelho. A hipótese alternativa de arquivo via listener FS
também permanece não verificada. Não houve leitura RPMB, banco de credenciais,
verificação de senha, escrita ou montagem adicional.

Após o pedido de identificação, SSH 172.16.42.1 expirou e não havia dispositivos
em `adb devices` nem `fastboot devices`; estado atual não confirmado. Nenhuma
reinicialização foi realizada. Retomar inventário passivo quando a conexão
retornar; não inferir Android, fastboot ou travamento só dessa ausência.

### Inventário passivo após retorno da conexão

SSH voltou ao mesmo Kali #39 (uptime 34 min; não houve reboot por nós). O
descriptor efetivo da UFS `1d84000.ufshc/geometry_descriptor/rpmb_rw_size`
continua `0x40`. O dispositivo SCSI `0:0:0:49476` e sua interface
`/dev/bsg/0:0:0:49476` pertencem a esse controlador; o número 49476 = 0xc144.
O fonte do kernel 7.3 define `UFS_UPIU_RPMB_WLUN=0xc4` e converte para SCSI
well-known LUN com `(id & ~0x80) | 0xc100`, resultando em 0xc144. Portanto há
uma interface SCSI correspondente ao RPMB UFS. Foram lidos somente sysfs e
metadados de `/dev`; nenhum comando SCSI/BSG, leitura de conteúdo ou escrita
RPMB foi emitido. A existência dessa interface NÃO prova que o Gatekeeper use
RPMB, nem localiza o objeto ou contador de falhas. Ela não fornece autorização
para qualquer acesso ao dispositivo.

Análise posterior do `keymaster_a.img` e HAL originais: o código de storage GK
seleciona RPMB (ID lógico 0x474b3232) ou SFS (`gk_sfs_file`) conforme resultado
de `qsee_query_rpmb_enablement`. Inicializar o storage pode criar partição
lógica/arquivo e escrever cabeçalho; não é operação garantidamente read-only.
Qual caminho está ativo permanece não observado. Detalhes e evidências em
`work/fingerprint-20261029/gatekeeper-offline/RESULTADO.md`.

O mesmo documento AOSP especifica que Gatekeeper deve escrever o contador de
falhas antes de verificar uma senha, limpando-o em caso de sucesso. Isto não
prova qual meio físico este aparelho usa; é um obstáculo concreto à regra de
não escrever. Não se realizou verificação nem se coletou credencial ou HAT.

`hat-frame.h` prepara somente o layout do frame FPC 3/3 para um HAT opaco de
69 bytes e rejeita versão diferente de zero e buffers curtos. Os testes em
`test-hat-frame.c` usam dados sintéticos e passaram com ASan/UBSan. O teste não
verifica HMAC, identidade, validade, origem ou autenticidade de um token, e não
se comunica com o telefone.

`km-bridge.h` monta requisição de 64 bytes `{0x205,2}` e, a partir de uma
resposta fictícia limitada a 0x3c0 bytes, monta um frame `{3,5}`. O teste
`test-km-bridge.c` passou com ASan/UBSan incluindo limites e tamanho malicioso.
É montagem offline com buffers sintéticos: não chama o TEE, não confirma que
esse comando do Keymaster é somente leitura nem valida um blob criptográfico.

## Teste de desafio FPC

Na mesma sessão experimental do Kali, app FPC 6, foi enviado somente módulo
3/cmd 2 usando buffers DMA já alocados, sem GPIO e sem Keymaster/Gatekeeper.
O retorno do TA foi zero e o desafio devolvido não era zero; seu valor não foi
impresso nem salvo. O comando altera o desafio e timestamp no estado volátil
do TA; não demonstra autorização válida, nem cria ou valida HAT. Não foram
abertos bancos de credenciais nem executadas verificações de senha.

No Kali, `qcomtee` e `/dev/tee0` estão presentes, mas não foram encontrados
processos Gatekeeper/Keymaster/Keystore. Sua presença não implica acesso ao
protocolo QSEECOM legado nem disponibilidade de um serviço autenticador.
Segundo a documentação AOSP de autenticação, o HAT de cadastro deve corresponder
ao desafio e à identidade autenticada; não há evidência de uma fonte legítima
para fornecê-lo nesta sessão. Não assumir que um HAT antigo seja reutilizável:
o TA também exige desafio correspondente e tempo limitado (~10 minutos).
