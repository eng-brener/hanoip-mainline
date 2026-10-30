# Suspend: s2idle não retorna (30/10/2026)

Relato do usuário: com a tela desligada por muito tempo, o aparelho parece
suspender por completo; é preciso apertar o power várias vezes e esperar
30–40 s para voltar.

## Evidência (somente leitura)

- Configuração vigente: `org.gnome.desktop.session idle-delay = 300` (5 min
  apaga a tela) e `gsd-power` `sleep-inactive-battery-type = 'suspend'` com
  `sleep-inactive-battery-timeout = 900` (15 min).
  Portanto o apagamento por ociosidade não é o problema: após 15 min o
  próprio ambiente pede **suspend** ao logind.
- Boot anterior (journal -1): às 17:06:18 `systemd-sleep[...]: Performing
  sleep operation 'suspend'...` seguido de
  `kernel: PM: suspend entry (s2idle)` e **o journal termina**, sem
  `PM: suspend exit`, `PM: resume` nem `Restarting tasks`. O boot seguinte só
  começa 17:09:24, ~3 min depois.
- `/sys/power/mem_sleep` oferece apenas `s2idle`; `/sys/power/state` expõe
  `freeze mem`. Não há `deep`.
- Boot atual: `success=0` em `/sys/power/suspend_stats`, ou seja, nenhuma
  suspensão completou.
- Conclusão: entrar em s2idle trava; não há resume registrado. Isso é
  compatível com o relato de precisar de vários toques no power e de uma
  demora longa para "voltar" — provavelmente um reboot forçado, não um
  resume.

## Não atribuir ao experimento de 120 Hz

Neste boot o suspend nem ocorreu. O travamento em s2idle aparece com o kernel
listener7 e o msm do rootfs também; o projeto registra suspend/resume como
nunca validado.

## Atualização 17:40 — o 2º travamento NÃO foi suspend

Às ~17:31–17:32 o aparelho travou de novo, mas `suspend_stats/success` estava
**0**: não houve suspensão. Observado: ping em 172.16.42.1 respondia, SSH
oscilava entre "banner exchange timed out" e conectar; quando conectou, load
average 9,4–9,5 em 8 CPUs. O dmesg tinha mais de 1775 linhas
`spmi spmi-0: disallowed SPMI write to sid=0, addr=0x6046`, desde ~71 s de
boot. Hipótese (não comprovada): laço de escrita/retry nesse registrador
SPMI saturando CPU; o dono não foi identificado.

**Informação nova do usuário: travou logo depois de abrir o Firefox.**
Reposiciona os suspeitos (todos não comprovados): hang do GPU/msm com
recuperação em laço, pressão de memória com swap em zram (1,8 GB) ou
compositor preso em commits. O laço SPMI já existia desde ~71 s de boot,
antes do Firefox, o que enfraquece a ligação causal. Coleta para a próxima
reprodução: `dmesg -w` (gpu/hangcheck/gmu), `/proc/meminfo` e zram a cada
5 s, `ps` por CPU e log do phoc.

## Correção de conclusão: s2idle não "sempre trava"

Em 28/10 o suspend funcionou por 31 s com o ADSP/remoteproc parado por
`/usr/lib/systemd/system-sleep/hanoip-adsp`, voltando com ADSP running e
usb0 restaurado (ver item 16 de `onde paramos.md` e
`work/cpu-20261028/SUSPEND-RTC-BOOT.md`). Logo a hipótese correta é: sem esse
hook — ou se ele não rodar — o suspend trava. **Não verificado** se o hook
está instalado neste rootfs nem se rodou às 17:06:18.


## Mitigação segura proposta (NÃO aplicada)

Desligar a suspensão automática, mantendo o apagamento de tela:

    su kali -c "gsettings set org.gnome.settings-daemon.plugins.power \
        sleep-inactive-battery-type 'nothing'"

Efeito: a tela continua apagando por ociosidade (5 min) e acorda na hora com
toque ou power; o aparelho deixa de tentar s2idle. Reversível com
`gsettings set ... 'suspend'`. É uma escrita em `/home/kali` (dconf) e por
isso precisa de autorização explícita.

## Correção de verdade (trabalho separado)

Fazer suspend funcionar exige tratar s2idle nesta plataforma: fontes de
wakeup, PSCI/system suspend no U-Boot/DT, suspensão de DSI/painel/reguladores
e retomada do touch (o firmware da IRAM é perdido quando o painel desliga).
Nada disso está implementado nem validado. Antes de tentar, precisa de plano
com recuperação conhecida, porque o sintoma atual é não voltar.
