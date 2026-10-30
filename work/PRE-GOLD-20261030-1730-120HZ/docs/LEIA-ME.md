# Candidato 120 Hz — preparado offline, não testado

**Correção 30/10:** o arquivo `panel-ilitek-ili7807s-120-experimental.ko`
descrito abaixo foi copiado do diretório errado: era um módulo antigo, não o
resultado da ligação experimental. Não utilizá-lo nem seus hashes como prova
do patch. A compilação do objeto candidato passou, mas a primeira ligação foi
copiada incorretamente. O módulo correto e o novo plano constam no fim.

Base exata: árvore v7/listener7 `276fbce0ae673c83e456cfe359c33ed3c4e3468b`.
O arquivo `baseline/` foi extraído via `git show` do volume original montado
somente leitura; `variant/` contém a alteração; `experimental-120hz.patch` é
um diff que passou `patch --dry-run` contra essa cópia.

O patch adiciona modo opcional apenas ao Tianma: 1080x2460, htotal 1136,
vtotal 2520, VFP 46, clock idêntico ao 60 Hz (~343458 kHz), ~119,976 Hz.
O modo existente permanece preferido. Nenhum DT, PPS, energia, sequência de
reset ou outro painel é alterado. Expor modo não prova seleção segura nem
switch sem falhas. Fontes e ressalvas em `docs/kernel/levantamento-tela-2026-10-30.md`.

Foi compilado somente `panel-ilitek-ili7807s.o` ARM64, com cópias isoladas
da árvore e objetos em volume Docker `hanoip-display120-test-20261030`, sem
alterar o volume baseline. Compilação sem erros; checkpatch sem erros e um
aviso de ausência de descrição de commit (diff ainda não é commit). Não é
uma imagem inicializável, não é um módulo instalado e não houve teste físico.

O módulo foi ligado em ambiente isolado e salvo como
`panel-ilitek-ili7807s-120-experimental.ko` (SHA256 49520443726a13223ec433510bbd1f6845061a1fd031ce69e768f45bcc27e8b7),
vermagic `7.3.0-sm7150 SMP preempt mod_unload aarch64`, depends
`drm_display_helper`, sem MODVERSIONS. Arquivo zstd tem SHA256
8a077791a99c2f85064c03702468bf5fb496b1c2bb1c920fc946e1d90cc34892.
Igualdade do vermagic/dependências não prova compatibilidade em execução.
O driver do aparelho está em
`/usr/lib/modules/7.3.0-sm7150/kernel/drivers/gpu/drm/panel/panel-ilitek-ili7807s.ko.zst`.
O ramdisk base contém cpio inicial seguido de initramfs zstd; este não contém
o módulo do painel nem msm. `hanoip-panel-120-init-bottom.sh` é um protótipo
de bind mount volátil sobre o arquivo do rootfs. Foi incorporado à imagem de
teste descrita abaixo, mas a tentativa não demonstrou o bind. Depende da ordem
udev, do alvo exato e da sobrevivência do mount no switch_root; a falha deve
deixar a baseline sem substituir arquivos.

## Tentativa autorizada de 30/10, ~16:27

Foi criada `kernel-listener7-panel120-test.img`, SHA256
eccf1aef78d8553ce3230d394aa7a5994477bbe4a5b9482d22b7a85c6e2a8348.
Kernel e DTB são idênticos aos de listener7; somente ramdisk foi alterado.
U-Boot cam-tres e a imagem foram iniciados por fastboot boot. Kali iniciou;
o arquivo visível do módulo tem hash
5e61e9dbd79c56394bbc9374abf33d56bc8fb49ff1e5f5e20c5748a426d259b1,
não o do experimental; findmnt mostra ext4 sem bind no alvo. Connector mostra
apenas 1080x2460, DSI error_snapshot irqs=0. Portanto o bind não foi observado,
o módulo experimental não foi demonstrado e 120 Hz NÃO foi selecionado nem
testado. O motivo do bind ausente ainda não foi identificado: não presumir que
o hook executou ou que switch_root removeu o mount. Aparelho segue ligado.

## Variante de diagnóstico preparada depois

`kernel-listener7-panel120-diagnostic.img`, SHA256
50e256ef3836261bbd17fd9dfb5adba672c1338616b0106cd3c1621cb4fd7d90.
Mesmo kernel e DTB do listener7; hook agora registra fases em
`/run/hanoip-panel-120.status` (RAM) e no kmsg. Sintaxe shell, zstd e hashes
verificados offline; o arquivo ainda não foi bootado. Após boot conferir marker,
mountinfo, hash, nome e modos, em vez de supor que o hook funcionou. 60 Hz
segue preferido; 120 Hz não está validado. Reboot exclusivamente no bootloader.

## Causa identificada e variante v2

Na segunda tentativa o marker `/run/hanoip-panel-120.status` mostrou `hook
iniciado` e `modulo ja carregado; mantendo baseline`. A inspeção do PRIMEIRO
cpio do initramfs comprovou que ele já contém o módulo original, carregado
antes do init-bottom. O bind não foi aplicado e não houve teste a 120 Hz.

Outro erro identificado: `make M=drivers/gpu/drm/panel modules` gravou o .ko
em `/test/linux/drivers/gpu/drm/panel/`, não em `/test/obj/...`. A cópia antiga
veio do lugar errado. A nova ligação usa o .ko do diretório correto, contém
o texto `hanoip: experimental 120 Hz candidate enabled`, e seu vermagic é
`7.3.0-sm7150 SMP preempt mod_unload aarch64`. SHA256 do .ko comprimido:
72e3d9f8f2b582c528fb3509eabde2c9d0cd2939a45868dbd128f2e8d6fc1ca5.

`kernel-listener7-panel120-early-v2.img`, SHA256
c2a2de5b3cd23df319b29fc496c0d1f5d2a1db3a8ef309430ea0a9063393b15b,
mantém kernel e DTB idênticos e insere um registro cpio para substituir a cópia
do módulo somente no initramfs, antes do udev, sem bind e sem alterar o rootfs.
Arquivo verificado offline: payload extraído corresponde ao hash acima. Boot
não executado. Conferir marker no journal e modos oferecidos antes de selecionar
120 Hz; verificação pelo arquivo do rootfs não prova qual módulo foi carregado.

### Boot v2 observado

Boot volátil em 30/10 ~16:33: journal do kernel confirma `hanoip: experimental
120 Hz candidate enabled`; sysfs de DSI-1 lista duas linhas 1080x2460 (sysfs
não informa frequência); DSI error_snapshot irqs=0; hash do módulo persistente
continua 5e61e9dbd79c56394bbc9374abf33d56bc8fb49ff1e5f5e20c5748a426d259b1.
Sessão estava no greeter, sem sessão gráfica kali, portanto wlr-randr no usuário
kali ainda não conectou e taxas/preferência não foram confirmadas em runtime.
Temperatura chegou a 76,1 °C no sensor cpu7 no primeiro levantamento de boot;
amostra posterior teve máximo 71,2 °C (cpu9), bateria 35,1 °C. NÃO selecionar
120 Hz nessas condições; aguardar arrefecer e login do usuário. Não houve teste
de troca nem confirmação visual neste boot.

### Tentativa de seleção em 30/10 ~16:35

Após login e esfriamento (máximo ~46,4 °C), `wlr-randr` confirmou os modos
60.000000 Hz preferred/current e 119.975998 Hz. O usuário autorizou testar.
`wlr-randr --output DSI-1 --mode 1080x2460@119.975998Hz` retornou 0, mas a
consulta imediatamente posterior e outra repetida mantiveram 60 Hz como
current. Journal do phoc registra atomic commit failed: Device or resource
busy no período e modeset a 60 Hz; isso não prova a causa exata nem se o
modo experimental chegou ao hardware. DSI error_snapshot permaneceu irqs=0.
Não se pode afirmar 120 Hz ativo, nem que a imagem em 120 Hz foi validada.
Não insistir com trocas cegas ou apagar/ligar painel para forçar; investigar
sequência do compositor/modeset e preservar a sessão atual.

### Modo 119,976 Hz aplicado — 30/10 16:37

Fonte upstream Phoc v0.58.0 `src/output.c`: conversão da solicitação usa
`head->state.mode` apenas se preferred; caso contrário lê custom_mode. Se
largura/altura estiverem vazias, o preenchimento escolhe o modo preferred.
Hipótese compatível com o primeiro teste; o fonte remoto pode diferir de patches
da distribuição. `wlr-randr --output DSI-1 --custom-mode 1080x2460@119.976Hz`
retornou 0 e passou a mostrar 119.975998 Hz current. DRM debugfs confirmou
`mode: 1080x2460: 120 343458 ... vtotal 2520`; journal Phoc registrou
`Modesetting ... 119.976 Hz`; DSI error_snapshot irqs=0 após a troca; máxima
temperatura amostrada 43,2 °C, bateria 36,1 °C. Não há confirmação visual do
usuário, medição independente de vblanks, teste prolongado ou repetição de
trocas. Phoc pode salvar estado ao aplicar; investigar retorno e persistência.

Às 16:38 o usuário relatou que a tela apagou no momento da troca e voltou ao
apertar o botão. Consulta posterior: 119.975998 Hz current no Phoc, timing
120/vtotal 2520 ativo no DRM, DSI irqs=0, temperatura máxima ~44,8 °C. Isso
não demonstra a causa do apagamento nem a estabilidade prolongada.

Às 16:39–16:40 usuário informou que imagem parece correta. Teste gráfico
Wayland `es2gears_wayland`, com cache Mesa desabilitado: primeiro ensaio de
12 s reportou 116,200 e 119,776 FPS; outro de 25 s reportou 117,941,
119,976, 119,400 e 119,952 FPS em janelas de cinco segundos. São quadros da
aplicação, não medida óptica independente. Após o teste, modo 119,975998 Hz
seguia current, DSI irqs=0, sem mensagens de GPU fault/GMU watchdog no journal
do boot, temperatura máxima 49,0 °C e bateria 37,2 °C. O toque segue enumerado;
não foi testada interação física neste ensaio. Arquivo de estado do Phoc
`/home/kali/.local/state/phoc/outputs.gvdb` existe; possível persistência do
modo não foi verificada. Não extrapolar para suspend, reboot, longa duração,
repetidas trocas ou desempenho de aplicações reais.

### Ciclos manuais de tela, ~16:41

O usuário apagou/acendeu repetidamente. Journal registra oito sequências de
desligamento e reativação entre 16:41:26 e 16:41:39, voltando a 119,976 Hz,
LCDB enabled com VREG_OK; DSI irqs=0. Duas tentativas de reativação do touch
falharam às 16:41:30 e :31 com `IRAM reload after panel power-on failed: -74`:
blocos IRAM foram verificados, mas resposta FW foi `f9 00...` em vez de
`21 10...`. Os ciclos seguintes registraram reload bem-sucedido, último às
16:41:39. Não prova a causa, nem atribui a falha a 120 Hz; ciclos foram rápidos.
Confirmar fisicamente touch agora e investigar, evitando novos ciclos rápidos.
Houve dois `Atomic commit failed: Device or resource busy` às 16:40:17,
antes dessa sequência. Temperatura máxima amostrada 49,9 °C, bateria 37,5 °C.

### Investigação de touch e EBUSY

### Trocas controladas, 16:46–16:47

### Repetição controlada, 16:48

Partida em 60 Hz, rejected=15/restarts=15, DSI irqs=0. Três trocas:
60→119,976 às 16:48:11, 119,976→60 às 16:48:18 e 60→119,976 às
16:48:25; todas rc=0 e modo confirmado. Nas duas primeiras a resposta FW
foi válida e reload bem-sucedido; rejected subiu de 15 para 17 e restarts
de 15 para 17, sem identificar causa ou impacto percebido. Na terceira,
16:48:26, resposta f9 e falha interna -74; restarts ficou 17, DSI irqs=0.
Sequência interrompida imediatamente, sem novo ciclo de recuperação. O código
mantém IRQ do touch desabilitada após falha; funcionalidade física não foi
confirmada após esta ocorrência. Sem EBUSY observado na janela consultada.
Temperaturas máximas amostradas antes e entre trocas 45,4/55,4/56,4/52,5 °C.
Esta ocorrência acompanhou uma troca de modo, diferente das anteriores em
ciclos de apagar/acender; não prova falha exclusiva de 120 Hz nem causa.

Relato posterior do usuário: a tela apagou na primeira troca e piscou durante
as seguintes; toque funcionando. Assim as trocas NÃO estão visualmente
validadas apesar de rc=0, modo confirmado e DSI irqs=0. Em consulta posterior,
o journal registra desligamento 16:48:38 e religamento 16:48:47 com resposta
FW correta e reload bem-sucedido; stats 3861/3843/18/18 e modo 119,976 Hz,
DPMS On. A origem do ciclo não foi determinada. Não repetir trocas até
investigar a anomalia visual e combinar retorno seguro.

### Teste no aparelho das correções DSI + 120 Hz, 17:15–17:22

Boot volátil: U-Boot cam-tres + `kernel-listener7-dsifix-120hz.img`
(SHA256 b951d85887680c78d646334deb23b2c85c6199d128715e9e4797cc5fa3f222e0).
Kernel e DTB byte-idênticos ao listener7 validado; só o ramdisk mudou, com
override de `msm.ko.zst` (SHA256 e45516ee..., vermagic limpo
7.3.0-sm7150, marcador `hanoip-dsi-guards` no binário) e do painel de 120 Hz
(SHA256 72e3d9f8...). Nada gravado em partição.

- Marcadores no dmesg confirmam o módulo novo e o painel experimental ativos.
- Login inicial: Phoc restaurou estado salvo e fez modeset direto a
  119,976 Hz, seguido de `Timeout (3000ms) expired with 1 configures pending`
  e tela preta relatada pelo usuário. DSI irqs=0 e nenhum `atomic commit
  failed` nesse ponto. Voltando a 60 Hz a imagem voltou.
- Troca explícita 60→119,976 Hz completou: modo no Phoc e no DRM (vtotal
  2520), LCDB ciclado com VREG_OK, reload do touch OK, DSI 0 e nenhum novo
  timeout. Usuário confirmou imagem correta.
- `es2gears_wayland` a 119,976 FPS; DSI 0; 45,4 °C.
- Seis trocas seguidas 120↔60: rc=0 em todas, 6 ciclos LCDB, 6 reloads de
  touch, **0 falhas de firmware e 0 respostas f9**, DSI 0, nenhum novo erro
  do Phoc, 41,9–43,8 °C.
- Ciclos de apagar/acender pelo compositor (`wlr-randr --off/--on`) NÃO são
  seguros: em 5 tentativas rápidas, 2 aplicaram (reload OK, sem f9) e 3
  retornaram rc=1; o Phoc acumulou timeouts/EBUSY e a sessão caiu para o
  greeter. Repetido com um único ciclo em 60/120 Hz, `--off` retornou 0 mas
  DPMS seguiu On, `--on` retornou 1 e a sessão caiu de novo (erros do Phoc
  13→36), apesar de LCDB e reload do touch terem sido bem-sucedidos e DSI 0.
  Temperatura chegou a 75,4 °C nesse estresse.
- Não atribuir a queda da sessão às correções DSI sem teste A/B: timeouts e
  EBUSY já existiam em boots com o msm original. Pendente comparar o mesmo
  ciclo com o msm sem correções.

### Item 1: login seguro (estado salvo do Phoc)

Objetivo: impedir que o Phoc reaplique 119,976 Hz sozinho ao abrir sessão.
Descoberto que o próprio Phoc já havia regravado
`/home/kali/.local/state/phoc/outputs.gvdb` (mtime 17:21:33) no instante da
troca para 60 Hz. Duas sessões seguintes carregaram o estado salvo e subiram
em **60,000 Hz**, preservando `Transform: normal` e `Scale: 3.000000`.
Backup em `/home/kali/.local/state/phoc/backup/outputs.gvdb.20261030-172411`
(566 bytes, SHA256 do arquivo original
3e36a888c36b576849a835bcd93aabcaa4b2a69debc9f18e18635c509a0c7a1c).
Não foi necessário editar o arquivo à mão.

**Correção de conclusão anterior:** a sessão atual, iniciada em **60 Hz**,
também registrou 13 `Atomic commit failed: Device or resource busy` e 1
`Timeout (3000ms)` nos primeiros segundos, e a imagem ficou normal. Logo o
timeout de início de sessão NÃO é exclusivo de 120 Hz e não explica sozinho
a tela preta de 17:16. O que está demonstrado é apenas que subir em 60 Hz
resultou em imagem correta nesta sessão.

Regra prática: se trocar para 120 Hz, voltar a 60 Hz antes de encerrar a
sessão, pois o Phoc salva o último modo e o próximo login o reaplicaria.



Partindo de 119,976 Hz, às 16:46:31 mudou para 60 Hz e às 16:46:35
retornou a 119,976 Hz; comandos rc=0, modos confirmados, DSI irqs=0 e
ambas as recargas IRAM registradas como bem-sucedidas. Stats passaram de
rejected=9/restarts=10 a 10/11; não demonstram impacto percebido.
Às 16:47:01–06 houve ciclos de tela não iniciados pelo teste de troca;
às 16:47:03 houve outra resposta FW f9 e falha interna -74, seguida de
recargas bem-sucedidas às 16:47:04 e :06. Às 16:47:09 uma terceira troca
controlada para 60 Hz retornou rc=0, modo e DPMS On confirmados, recarga
IRAM bem-sucedida e DSI irqs=0. Stats posteriores rejected=15/restarts=15,
mas incluem os ciclos intermediários e não podem ser atribuídos à troca.
Máxima térmica amostrada após essa troca 49,0 °C. Teste interrompido diante
da nova falha interna e dos ciclos intermediários; não houve confirmação de
falha percebida no toque. Estado final observado: 60 Hz.

Usuário confirmou touch normal depois dos ciclos. Stats lidos posteriormente:
irqs=3519 reports=3511 rejected=8 restarts=9; são contadores acumulados do
boot, não evidência de quando ou por que os oito pacotes foram rejeitados.
O código exato v7 `patches/0125-hanoip-touch.patch` distingue dois pontos de
erro -EBADMSG: leitura de retorno da IRAM e resposta inesperada na checagem do
firmware. Nos dois casos observados os três blocos foram verificados com sucesso
antes da resposta `f9 00...`; logo a falha observada é a segunda, no teste
`version[0] != 0x21 || version != 0x10000a00`, não mismatch dos blocos.
O worker retorna sem religar IRQ se `ili_start()` falha; reativação posterior
bem-sucedida habilita a IRQ novamente. A sequência de eventos mostra espera de
~450 ms da alimentação até a resposta, seguida de novos ciclos logo depois.
Timing/firmware ainda não pronto ou interação com ciclos rápidos são hipóteses,
não prova; faltam controles a 60 Hz, teste de separação e captura de protocolo.
Não aumentar atrasos, repetir comandos ou ativar IRQ às cegas.

`LEVANTAMENTO-GPU.md` registra EBUSY em boots anteriores a 60 Hz e identifica
uma origem possível em `drm_atomic_helper_setup_commit`, mas as ocorrências
do boot de 120 Hz não têm trace suficiente para afirmar mesma causa. Duas às
16:40:17 antes dos ciclos e outra posteriormente; não associar automaticamente
ao Ilitek ou à taxa. Faltam contagem por janela, contexto preciso, trace
seguro e comparação controlada. DSI irqs=0 não cobre todos erros DRM/Phoc.

Antes de qualquer boot: criar receita própria que não use o `git reset --hard`
da receita v7 em volume compartilhado; comitar a variante na cópia isolada,
conferir kernel.release e vermagic sem `+`, empacotar Image.gz e determinar
como carregar o módulo experimental sem substituir o arquivo persistente do
usuário. Qualquer escrita no aparelho precisa de autorização específica; não
supor que `fastboot boot` atualize módulos que moram no rootfs.
