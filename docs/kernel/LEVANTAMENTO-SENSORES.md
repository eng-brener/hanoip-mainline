SENSORES NO KALI (SSC/ADSP + libssc + iio-sensor-proxy) — 28/10/2026
=====================================================================
Estado: acelerômetro (rotação), luz e proximidade FUNCIONANDO. A rotação estava
180 graus errada e foi corrigida sem rebuild de kernel/U-Boot.

1. ARQUITETURA (importante para não procurar no lugar errado)
-------------------------------------------------------------
  Os sensores NÃO aparecem em /sys/bus/iio/devices (lá só existem os dois ADCs
  do PMIC: c440000.spmi:pmic@0:adc@3100 e @4:adc@3100).
  O caminho real é:
    ADSP (remoteproc 62400000) -> fastrpc -> hexagonrpcd -> libssc -> iio-sensor-proxy
  Prova: ldd /usr/libexec/iio-sensor-proxy mostra libssc.so.2, e o driver SSC
  do proxy descobre o sensor pelo device misc /dev/fastrpc-adsp
  (regra udev /etc/udev/rules.d/99-hanoip-ssc.rules define
   IIO_SENSOR_PROXY_TYPE="ssc-accel ssc-light ssc-proximity").

  Consequência prática: ACCEL_MOUNT_MATRIX de udev É o caminho de correção
  (setup_mount_matrix lê a propriedade udev do device misc), mas qualquer
  ajuste em sysfs iio não se aplica — não há device iio para accel.

2. O BUG DA ROTAÇÃO (medido, não suposto)
-----------------------------------------
  O libssc avisa no journal:
    "Mount matrix provided by firmware is all 0, falling back to identity matrix!"
  O registry do ADSP entrega a matriz zerada, então o proxy usa identidade.
  Com identidade os eixos crus saem assim (leitor próprio compilado contra
  libssc, ver seção 4):
    deitado (tela para cima): x=-0.42  y=-0.02  z=+9.92   -> face-up OK
    em pé, retrato normal:    x=+0.30  y=+9.77  z=-0.10   -> ERRADO (esperado y=-9.81)
  orientation_calc() do proxy faz atan2(y, ...) e conclui "bottom-up" em
  retrato, então o compositor vira a tela 180 graus.

  CORREÇÃO: negar X e Y (rotação de 180 no plano XY = diag(-1,-1,1)), no device
  misc do fastrpc:
    ACCEL_MOUNT_MATRIX="-1,0,0;0,-1,0;0,0,1"
  Resultado medido depois: em retrato o proxy reporta "normal" e o usuário
  confirmou a tela correta.

  Arquivo aplicado: /etc/udev/rules.d/99-hanoip-ssc.rules
  (cópia neste repo em work/nethunter-pro-20261026/hanoip-support/)
  Formato exigido pelo proxy: 3 grupos de 3 números separados por ";" — o
  parser é strsplit_num_tokens(mtx, ";", 3).

3. PROXIMIDADE: NÃO estava invertida (verificado)
-------------------------------------------------
  Medido com monitor-sensor:
    dedo tampando o topo -> "Proximity value changed: 1"
    dedo removido        -> "Proximity value changed: 0"
  A percepção de "ao contrário" vem do mesmo problema de rotação: com a tela
  virada, tocar/olhar o aparelho confunde a leitura do gesto. Nenhum ajuste
  foi necessário (não existe knob só-para-SSC; PROXIMITY_NEAR_LEVEL vale para
  o caminho iio, não para SSC).

4. LEITOR CRU (ferramenta de diagnóstico, /tmp/accel)
-----------------------------------------------------
  Compilado no próprio aparelho depois de instalar
  gcc libssc-dev libglib2.0-dev pkg-config:
    gcc -O1 -o /tmp/accel accel.c $(pkg-config --cflags --libs libssc glib-2.0)
  O programa conecta o sinal "measurement" (assinatura
  SSCSensorAccelerometer*, gfloat x, gfloat y, gfloat z, gpointer) e imprime
  os eixos crus — sem passar pelo proxy, é a fonte da verdade.
  Usar: /tmp/accel 6   (6 segundos de amostras)

5. INTERMITÊNCIA ("funcionam quando querem") — o que foi encontrado
------------------------------------------------------------------
  a) No suspend/resume o systemd PARA e INICIA o iio-sensor-proxy
     (journal: SERVICE_STOP -> Started em 11:05:05). Isso é esperado: o hook
     /usr/lib/systemd/system-sleep/hanoip-adsp desliga o ADSP antes do s2idle
     (senão o firmware do ADSP morre com err_qdi.c:1040) e religa depois.
     Depois do resume os três sensores voltaram a responder (accel cru ok,
     luz 84,6 lux, prox 0) — sem intervenção.
  b) A TELA DE BLOQUEIO NÃO SEGUE A ROTAÇÃO. Confirmado pelo usuário: com a
     tela bloqueada, girar o aparelho não muda nada. É por desenho (o teclado
     do PIN não pode girar enquanto se digita). Consequência: se você bloquear
     com o aparelho girado, a tela de bloqueio fica girada — não é sensor
     quebrado.

6. ITEM ABERTO (não é sensor)
-----------------------------
  Com o aparelho em retrato, bloqueado ou não, o compositor mantém
  "Transform: 180" (lido com wlr-randr) e a orientação do sensor é "normal".
  Desbloqueado o usuário confirma imagem correta; a tela de BLOQUEIO aparece
  180 graus girada em relação a ela, mesmo com o aparelho em retrato no
  momento do bloqueio. Só existe UM compositor (phoc 4532, usuário kali) e o
  socket do greeter (/run/user/996/wayland-0) é órfão — nenhum outro processo
  desenha a tela. Hipótese a testar: reiniciar a sessão gráfica (logoff/login)
  para que phosh recrie tudo já com a matriz corrigida. Não foi feito sem
  autorização porque exige o PIN do usuário.
