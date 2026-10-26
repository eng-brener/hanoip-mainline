Sensores — teste real ADSP/FastRPC/libssc, 26/10/2026

RESULTADO: acelerômetro, luz e proximidade produziram amostras reais no Linux.
Acelerômetro: 382 amostras em teste de 20 s; exemplos X=-0,074260,
Y=0,091028, Z=9,950818 m/s², coerentes com gravidade no eixo Z.
Luz: valores observados entre 0 e 72,5 lux durante cobertura/descobertura.
Proximidade: 13 eventos observados, alternando FAR/NEAR (12 transições).
Luz/proximidade executados juntos por 35 s. Giroscópio não testado: o
ssccli utilizado não oferece essa opção. Sem integração ao Plasma ainda.

BOOT E SEGURANÇA
Boot volátil U-Boot perif-v5 + kernel #6/DT de v6-qrtr, preservados.
Kit: work/sensors-20261026/ssc-ram-test/; hashes em SHA256SUMS.
Imagem bootada: kernel-hanoip-ssc-ram-v1.img.
Rootfs/registry/config/firmware/ferramentas em RAM, sem montagem de UFS.
Guardas MOUNTS_RAM_ONLY e BLOCK_GUARD_OK; kernel tainted=0 após amostras.
/proc/mounts contém apenas rootfs/proc/sysfs/devtmpfs/tmpfs/configfs e binds
correspondentes no chroot. Nenhuma escrita em partição. Não promoveu GOLD.
Telefone permanece no diagnóstico USB serial, sem Plasma por intenção.

EXECUÇÃO
ADSP subiu com firmware qcom/sm7150/motorola/hanoip/adsp.mdt.
FastRPC criou /dev/fastrpc-adsp e QRTR publicou serviço SSC 400, v1,
instância0, node5/port14. hexagonrpcd 0.4.0 e libssc 0.4.3 em Alpine 3.24.
179 arquivos de registry Android servidos a partir da cópia em RAM.
Avisos de registry/metadata ausentes e tentativas recusadas de escrita
.temp.json não impediram amostragem; não acessaram persist real.

A primeira execução automática parou por ordem incorreta de módulos
(qcom_common antes de qcom_glink_smem). Corrigida no MESMO boot carregando:
qcom_glink_smem qrtr-smd qcom_sysmon qcom_pil_info qcom_common qcom_q6v5
qcom_q6v5_pas fastrpc, e reiniciando start-sensors. Não precisou novo kernel.
Script local start-sensors corrigido; a imagem v1 preserva a ordem inicial
e exige a correção manual registrada. Não tratá-la como autostart validado.

EVIDÊNCIA
run1/volatile-boot.json, initial.txt, module-error.txt, retry2.txt,
ssc-status2.txt, accelerometer-summary.txt, physical-samples.txt.
physical-samples.txt registra valores, contagem 382, taint0 e mounts.

PRÓXIMO
Integrar o caminho já validado à variante pmOS em RAM: iniciar dependências,
pd-mapper e hexagonrpcd antes do consumidor libssc; depois validar integração
com iio-sensor-proxy/rotação e brilho automáticos. Não houve esse teste ainda.
Não repetir overlay AP SE11; câmeras e digital seguem pausadas.

ATUALIZAÇÃO — GIROSCÓPIO TESTADO NO MESMO BOOT, 26/10
ssccli --sensor=gyroscope --timeout=30 funcionou, apesar de a ajuda omitir
essa opção. A conclusão anterior de que a opção não existia estava errada.
665 amostras; valores por eixo: X -2,670616..2,384060;
Y -1,890843..2,684464; Z -4,603004..1,587243. Há repouso próximo de zero
e variação de ambos os sinais em todos os eixos durante movimento.
Tainted=0; mounts continuam apenas RAM/pseudo, sem partições.
Firmware retornou mount matrix zerada; libssc usou identidade. Orientação
dos eixos e calibração não validadas. CLI imprime m/s para giroscópio;
não tomar essa etiqueta como validação da unidade/escala angular.
A leitura serial desconectou uma vez durante coleta; reconexão recuperou
o log completo do mesmo boot (uptime655,97 s). Não atribuir causa ao sensor.
Evidências: ssc-ram-test/run1/gyro-help.txt, gyro-start.txt,
gyroscope-results.txt e gyroscope-summary.json.
Sem alteração de kernel/imagem, instalação ou escrita em partição.
