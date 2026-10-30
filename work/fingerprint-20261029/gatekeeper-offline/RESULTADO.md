# Investigação do armazenamento Gatekeeper — análise estática

## Identidade dos artefatos

* `work/android-dump-20261025/partitions-a/keymaster_a.img`: SHA-256
  `e0468868823289ebc244315b5ac4d337c4f7cf8d4b7ff8866555d36297fe1e6b`.
* `gatekeeper-hal.so`: SHA-256
  `0c56784e085135c990e6c3fe8790646bbfd336d3dedc594809d07c88c1f5c187`.
* `libkeymasterdeviceutils.so`: SHA-256
  `1d4b5f56a50e779037a62f11ab9fbdfebaa98604b64e8455c6928d5934b7f7da`.
* `librpmb.so`: SHA-256
  `debeb6c75b9e45a261152bb312e5f78bb58c554df39d49a4205e89aaee210912`.

Estes arquivos já tinham sido coletados; análise apenas no computador. O HAL,
as bibliotecas e keymaster_a vieram de dumps em datas diferentes: pertencem ao
mesmo aparelho segundo o histórico, mas equivalência de versões não foi provada.

## Fluxo observado no código enviado

1. HAL Gatekeeper QTI tem caminhos `verify` e `verify_legacy`; ambos chamam
   `KeymasterUtils`, montam dados de autenticação e enviam comando via QSEECom.
   No caminho legado, comando é `0x1002` ou `0x1502` conforme seleção em runtime.
   Evidência REA `ev_00000b96fffb3da8ee732dc8160892b4672a9628de29165f55cc1f121d4b906a`
   e `ev_1b888d63e3052c9dba648dd3c5328818a4d325fa6e6a9ed1394f2b8658f0c072`.
2. A biblioteca `KeymasterUtils` espera a propriedade Android de listeners e
   abre `keymaster64`, com fallback para `keymaster`; `spu_init` nessa biblioteca
   específica simplesmente retorna 0. Evidências
   `ev_35d010636ab7212fb5cc79786cd8e26ab14b7b02d5f360a02744f2f1658e17d5`,
   `ev_5095a80731b39e6816d9b9558a3a1925f74907ab6109d7b83def7850bced7911`.
   Isto demonstra caminhos possíveis do HAL, não qual ramificação foi usada em
   Android nem que esse ELF seja idêntico à instância residente atual.
3. No keymaster_a, `open_storage_platform` (REA Ghidra `0x11b87c`, imagem base
   `0x100000`) consulta `qsee_query_rpmb_enablement`. Se habilitado, inicializa
   storage QSEE e abre uma **partição lógica interna** ID `0x474b3232`, tamanho
   `0x18` passado a `qsee_stor_add_partition` se ela não existir. Código também
   abre/cria partição lógica de Keymaster separada. Não confundir IDs lógicos
   com partições GPT; não se conhece a posição física dos objetos.
   Evidência `ev_e862afe0b06c2cb0aec886e4fa0621e5f4f27fa52b1e6f55beda77c06bd382`.
4. A inicialização do storage Gatekeeper (`0x115428`) chama `0x11b380`: quando
   flag de backend RPMB está ativa, lê setores da partição GK e pode escrever o
   cabeçalho se os dados não corresponderem; caso contrário abre ou cria o
   objeto SFS `gk_sfs_file`, lê e pode escrever sua inicialização. A simples
   inicialização portanto NÃO deve ser tratada como somente leitura.
   Evidências `ev_37bd5f40b6975a386cdd2bf92c4388d06ffa5188a937bd9fc697fecc0ac0e7e3`,
   `ev_73b8e40d1ea554a4607f245ab71098ccd8e7ccfbc894e5a70636cc7aae825861`.
5. `gk_modify_user_data` (`0x115cfc`) chama rotina de sync `0x11585c`; ela
   calcula integridade e chama `gk_write_platform` `0x11b224`. Com flag RPMB
   ativa, chama `qsee_stor_write_sectors` na partição GK; caso contrário chama
   `qsee_sfs_write` no objeto `gk_sfs_file`. Evidências
   `ev_47d0710a7d1fc518057850d1e87d5375870fa40508e3764ebebddaffdc8a8f31`,
   `ev_522dec71c46f6efc44d939b56625af44861bb72d5429ff0ce751c75a1bf0f5db`,
   `ev_ecf17c5fd51f4ac0ea193cee7936ebd272bed3de9d71ff4b55beda77c06bd382`.
6. `librpmb.so` do dump implementa abertura de `/dev/sg*`, identificação de
   LUN e escrita UFS via SG_IO. Evidências
   `ev_9eea22795a388e9e69576e49ed75027b6a9f645d9eec8b865f5ee2471827471e`,
   `ev_ee7526d83ffcd0cf42b0fb5701de39b65c7fbf1b805a464a993052998897bde9`.
   Isso mostra capacidade do stack Android, não sua execução nesta sessão.

## O que permanece desconhecido

O valor retornado por `qsee_query_rpmb_enablement` e o ramo selecionado na
sessão atual não foram observados. Não há prova de que este aparelho use a
partição lógica RPMB GK em vez de SFS, nem de localização exata do contador
físico, nem da criação prévia de objetos. As strings `GK_VERIFY` e
`gk_get_rpmb_data` existem no ELF, mas não bastam para estabelecer vínculo
executado entre uma verificação e determinada gravação física. A análise estática
não comprova qual backend é ativo. Não foram emitidas chamadas ao Keymaster ou
Gatekeeper, comandos RPMB/SG, nem lidos registros de credenciais. Nenhuma
partição foi escrita ou montada para esta investigação.

O SSH deixou de responder durante a análise; não se assume que houve reboot ou
que o aparelho esteja em qualquer modo específico. Evidência exportada em
`rea-keymaster-evidence.json` e `rea-storage-flow.json`.

## Despacho e seleção de inicialização — análise adicional

O dispatcher `0x109848` percorre 67 entradas de 16 bytes em `0x137580` e só
chama `open_storage_platform` `0x11b87c` quando o segundo byte de flags da
entrada é não zero. Na tabela relocada observada (REA
`ev_93d6dd6e7b313f8f74692041d4cf67e0e35aad11bbcabde3fd33a4e6cfe5a9e5`):

* `0x205 GET_AUTH_TOKEN_KEY`: flags `00 00`, handler `0x118494`;
* `0x21002 GK_NEW_VERIFY`: flags `00 01`;
* `0x1502 GK_SB_VERIFY`: flags `00 01`.

Logo, neste dump, o dispatcher não exige `open_storage_platform` para 0x205,
mas o exige para os dois comandos de verificação acima. Isso é evidência do
fluxo estático, não execução nem garantia de que o firmware residente seja
idêntico. Outros helpers internos/serviços externos podem ter efeitos não
observados. No handler 0x205 (`ev_8290becc692c4cb0a321bc77875975f594f3793edcb30744d0574b389201f180`),
a resposta encapsulada é produzida por `qsee_encapsulate_inter_app_message`;
o helper `0x106938` no caso correspondente usa PRNG e cache em memória
(`ev_875052db01ce0cc6cb27af76d8067d34169671d2ae69b1370152bc9f343da121`).
O TA também consulta propriedades para selecionar o destino de autenticação.
Não foram analisados internamente os serviços externos chamados pelo TEE, logo
não se afirma ausência de escrita ou compatibilidade de uma chamada ao vivo.

O estado ativo RPMB versus SFS continua desconhecido; a leitura da tabela não
revela o resultado dinâmico de `qsee_query_rpmb_enablement`. Nenhum comando
Keymaster/Gatekeeper foi executado. Evidência adicional exportada em
`rea-dispatch-flow.json`.
