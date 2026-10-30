# Kali NetHunter Full no hanoip — instalação no rootfs (30/10/2026)

Pedido do usuário às 15:47: "vamos instalar agora kali nethunter full".

## O que é
O metapacote do Kali é **`kali-nethunter-full`** ("NetHunter rootfs packages -
Full variant", candidato 2026.4.2). Existe também `kali-nethunter-nano` e
`kali-nethunter-core`, além do transicional `kali-linux-nethunter`.

## Simulação (antes de instalar)
`apt-get install -s kali-nethunter-full`:
- **567 pacotes novos, 2 atualizados, 0 removidos**, 64 não atualizados
- download: **959 MB**
- atualizados: `libtag2` e **`wpasupplicant`** (o Wi-Fi/SSH pode cair durante o
  upgrade; existe o console serial USB `/dev/cu.usbmodemhanoip_kali3` como
  reserva, via `/dev/ttyGS0`)
- traz XFCE/Xorg completos (não sobem sozinhos; a sessão continua Phosh),
  Metasploit, Postgres, mitmproxy, etc.
- **não** atualiza glib/mesa/libfprint/waydroid → a pilha de digital em
  /opt/hanoip-fprint e o Waydroid não são tocados pelo install

## Estado anterior guardado no aparelho
- `/root/before-nethunter-full-20261030.txt` (dpkg -l, 1664 linhas)
- `/root/before-nethunter-full-manual-20261030.txt` (apt-mark showmanual, 123)
- `/root/before-nethunter-full-units-20261030.txt` (unidades habilitadas, 69)
- 53 unidades rodando; wlan0 10.0.0.44; 92 GB livres

## Como foi rodado
```
tmux new-session -d -s nth \
  "DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
   apt-get install -y kali-nethunter-full 2>&1 | tee /root/nethunter-full-install-20261030.log"
```
Dentro de `tmux` para não morrer se o SSH cair. Log no aparelho:
`/root/nethunter-full-install-20261030.log`.

## O que verificar depois
1. `dpkg -l | grep -c ^ii` (antes: 1658)
2. phosh/pipewire/waydroid ainda sobem; `systemctl --failed`
3. unidades habilitadas vs. a lista de antes (principalmente Wi-Fi e pipewire)
4. RAM em uso (o aparelho tem 3,5 GB) e se Postgres/Metasploit não sobem
   sozinhos no boot
5. digital: `fprintd-list kali` e o app Digital continuam funcionando
6. espaço em disco e limpeza de `/var/cache/apt/archives`

## Ainda pendente (não feito neste passo)
- Anotar o resultado em `onde paramos.md` e no inventário do rootfs
  reproduzível (`work/rootfs-kali/`), que precisa refletir o conjunto de
  pacotes novo.
