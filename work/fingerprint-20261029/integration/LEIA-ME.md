# Integração da digital no Kali (30/10)

## Já instalado no aparelho
- pacotes: fprintd, libpam-fprintd (perfil PAM NÃO habilitado; vem com
  `Default: no`), meson, ninja-build, gcc/g++, pkg-config, libglib2.0-dev,
  libgusb-dev. O apt atualizou a GLib 2.90.0 -> 2.90.1. Log em
  /root/backup-fingerprint-20261030/apt-install.log
- libfprint 1.94.10 + driver hanoip_fpc em /opt/hanoip-fprint/lib
  (fonte: ../libfprint/driver/ e ../libfprint/src/; build em
  /root/build/libfprint). A libfprint do sistema não foi tocada.
- /etc/systemd/system/fprintd.service.d/hanoip-fpc.conf: env FP_HANOIP_FPC,
  LD_LIBRARY_PATH, DeviceAllow de /dev/qseecom-fpc e char-gpiochip,
  ReadWritePaths=/var/lib/fpc-gk.
- módulo: /lib/modules/7.3.0-sm7150/updates/qcom_qseecom_fpc.ko,
  /etc/modprobe.d/qcom-qseecom-fpc.conf (region_phys=0 listener_id=0x2000
  rpmb_writes=1), /etc/modules-load.d/qcom-qseecom-fpc.conf. Só carrega no
  kernel listener7 ou posterior; no kernel da PRE-GOLD falta símbolo e o
  modprobe apenas registra erro.
- backup do PAM original: /root/backup-fingerprint-20261030/pam.d

## App "Digital" + desbloqueio + sudo (pronto, NÃO instalado)
A instalação permanente foi bloqueada pela política do Claude Code
([Security Weaken]); precisa ser feita pelo usuário:

    sh work/fingerprint-20261029/integration/install-digital.sh    # instalar
    sh work/fingerprint-20261029/integration/uninstall-digital.sh  # desfazer

O instalador deixa: desbloqueio da tela LIGADO, sudo pela digital DESLIGADO
(liga pelo app). Peças:
- hanoip-digital: app GTK4/libadwaita (lista, cadastra com progresso,
  exclui; interruptores; estado; lockdown).
- hanoip-fp-guard: serviço + porteiro. Política Android: digital só depois
  de login/PIN desde o boot; 72 h sem PIN; 5 erros -> 30 s; 20 -> só PIN;
  lockdown; tela apagada não desbloqueia. Interruptores em /etc/hanoip-fp,
  estado público em /run/hanoip-fp/status.json. 17 testes
  (test_hanoip_fp_guard.py).
- hanoip-fp-admin + org.hanoip.fingerprint.policy: liga/desliga via pkexec
  (pede a senha do usuário).
- 50-hanoip-fprint.rules: cadastrar/excluir digital pede a senha.
- sudo: 2 linhas no /etc/pam.d/sudo, inertes sem /etc/hanoip-fp/sudo-enabled.
Diferença do Android: lá parte disso é imposta dentro do TEE; aqui é um
processo root. Sem detecção de dedo falso (o TA vem sem liveness).
Validado no aparelho (sessão de teste com unidade transitória): PIN arma,
digital certa desbloqueia, dedo errado conta erro e não desbloqueia.

## Uso
    fprintd-enroll -f right-index-finger kali   # cadastrar (máx. 5 no TA)
    fprintd-verify kali
    fprintd-delete kali                          # apaga também no TA
