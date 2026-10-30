# Teste auditado — 29/10

Boot volátil: U-Boot PRE-GOLD-20261029-1534 e kernel experimental #39.
Módulo corrigido carregado de /tmp (tmpfs), com `region_phys=0`, sem
carveout e sem endereço físico forçado. Frame DMA coerente alocado pelo kernel
em 0xfe100000; controle em 0x802c9000. TA carregado com app_id 5.

* Build-info módulo 12 cmd 1: quatro chamadas seguidas, todas no mesmo frame;
  retorno SCM 0, `rsp[0]=0`, JSON de 787 bytes, exit 0. A tese anterior de
  carveout obrigatório e de rotação obrigatória não se sustenta neste teste.
* Módulo 10 cmd 0, com GPIO29/4 solicitados e GPIO90 configurado: `rsp[0]=0`,
  mas os campos observados são zeros; isto não prova comunicação com o sensor.
* Em uma única execução, mantendo os GPIOs solicitados, cmd 0 novamente retornou
  zero e cmd 1 retornou `rsp[0]=1`. O cliente parou conservadoramente. O
  significado de 1 não está estabelecido; pode ser valor legítimo ou erro.
  A mensagem adicional `Success` é enganosa e não é evidência de sucesso.
  Não houve teste de toque, captura comprovada, identificação ou cadastro.
* Sem gravação de partições nem persistência de templates. Não se acessou
  diretamente o carveout `qseecom@9e400000`.

Próximo passo: verificar estáticamente no HAL e no TA a semântica de módulo
10 cmd 1 e sequência correta; corrigir o tratamento por comando (há comandos
que retornam valores positivos legítimos) e manter GPIOs em uma sessão única.

## Correção de tabela e teste seguinte

O TBB tem bytes `06 42 5d 63 69 cb` em ordem real: cmd 0 inicializa,
cmd 1 verifica finger-lost, cmd 2/3 preparam espera, cmd 4 captura e cmd 5
adormece. A antiga tabela no documento de protocolo estava invertida por
meia-palavra. O HAL distingue explicitamente o retorno 1 do cmd 1 e pula
os preparativos de espera quando flags=0; REA TA
`ev_077366e3717c9e0cd5f5647a430437057f8234d8dd2005d447be469d1c025c5a`.
Teste flags=0 com GPIOs mantidos: cmd 0 status 0, cmd 4 status 3 e frame+0x10
1002, cmd 5 status 0. Não foi verificada a ausência de dedo, nem a semântica
completa de 3/1002; não é prova de captura de imagem. Nenhuma partição escrita.

## Comparação com pedido de toque e controle

Na sessão de toque, usuário confirmou que encostou; IRQ após ~31 ms da
preparação cmd 3, cmd 4 rsp=0 e frame+0x10=0. Não há sincronização exata
entre dedo e IRQ nem prova de imagem. Em seguida pediu-se afastar o dedo:
IRQ após ~41 ms, cmd 1 rsp=1, cmd 4 rsp=3 e frame+0x10=0; confirmação de
que o dedo estava afastado foi dada pelo usuário. IRQ aparece nas duas execuções,
portanto não deve ser assumida como prova de toque; pode estar enfileirada
antes da espera. Não houve cadastro nem gravação de partições.

Após adicionar descarte dos eventos já pendentes: controle solicitado sem
dedo descartou 16 eventos e expirou após 25 s sem IRQ nova; tentativa seguinte
com toque solicitado também descartou 16 e expirou sem IRQ. O momento do
toque ainda não foi confirmado: pode ter ocorrido antes da espera armada,
ou a sequência/polaridade/funcionamento da IRQ pode estar incorreta. Não
concluir que o sensor funciona nem que está defeituoso.

Teste sincronizado: usuário confirmou três toques após espera armada; nenhuma
borda de descida foi observada. O driver Android coletado
`work/fingerprint-20261026/motorola-source/fpc1020_tee.c:396` usa
`IRQF_TRIGGER_RISING`, enquanto o cliente experimental usava FALLING. A borda
foi corrigida para próxima tentativa; sua eficácia ainda precisa ser testada.

Com borda de subida, descarte de 16 eventos iniciais e espera confirmada como
armada antes do pedido, usuário confirmou toques: houve IRQ ~14,6 s após cmd 3;
cmd 4 retornou rsp=0 e frame+0x10=0; cmd 5 rsp=0. Isso demonstra uma captura
com retorno de sucesso correlacionada temporalmente ao toque, não valida ainda
qualidade da imagem, reconhecimento ou cadastro. Controle posterior solicitado
sem dedo: após descarte de 16 eventos, nenhuma IRQ nova durante 25 s; o processo
foi encerrado pelo timeout 124; confirmação do usuário sobre o controle pendente.

Controle sem dedo foi confirmado pelo usuário. No primeiro enroll, uma captura
retornou 1 e foi interrompida; na tentativa seguinte houve captura 0 e módulo
11 cmd 2 retornou 6. TA em 0x5b6–0x5c2 devolve 6 se restam amostras: não é
falha genérica; frame+8 indica a quantidade. Cliente atualizado para aceitar
esse retorno específico; cadastro e reconhecimento ainda não comprovados.

## Amostras completas, finalização bloqueada

Na instância app_id 6, o contador do TA foi de 11 até zero, com captura e
último enrol retornando zero. O comando 11/3 retornou `0xe913406f`, nenhum ID
foi devolvido e cadastro não está confirmado. O TA `0x5fe` chama
`fpc_check_enrollment_allowance`, que chama `0x3cb0`; essa função retorna
`0xe913406f` quando o campo de chave hw_auth (`ctx+0x88`) está zerado. Antes
de adicionar fingerprint ao banco exige chave e autorização; não contornar essa
verificação. O fluxo legado usa keymaster64 e token de autenticação, mas sua
reprodução no Linux permanece por implementar e validar. As IRQs em alguns
ciclos chegaram rapidamente, portanto número de contatos distintos não foi
estabelecido apesar do avanço do contador. Nenhum template foi persistido.

Consulta de nome via módulo somente de lookup localizou keymaster64 residente
(status 0, app_id 1 nesta sessão). Nenhum comando foi enviado ao keymaster;
detalhes do HAL, HAT e limitações: `keymaster-lookup/NOTAS.md`.
