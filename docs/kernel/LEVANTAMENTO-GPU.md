VARREDURA COMPLETA DA GPU — Adreno 618 / sm7150 (hanoip), 28/10/2026
=====================================================================
Método: hardware -> DT -> kernel -> runtime -> userspace. Cada linha tem a
origem do dado (comando, caminho sysfs/debugfs ou arquivo do fonte). Nada foi
inferido sem marcar como inferência.

Resumo: a GPU está COMPLETA em desempenho, API e gerenciamento de energia.
As duas "pendências" que eu havia anotado antes estavam ERRADAS (erro de
medição meu): as GDSC da GPU existem E desligam quando ociosa.


1. HARDWARE
-----------
  SoC/GPU ......... Adreno 618
  revision ......... 618 (0x06010800)      /sys/kernel/debug/dri/0/gpu
  Vulkan deviceID .. 0x6010800             vulkaninfo (Turnip)
  speed bin ........ 3 (INFERIDO do filtro de OPP, ver 4.1)
  memoria .......... ICC gfx-mem: gem_noc MASTER_GRAPHICS_3D ->
                     mc_virt SLAVE_EBI_CH0 (QCOM_ICC_TAG_ALWAYS)
  IRQ .............. GIC_SPI 300
  SMMU ............. adreno_smmu (5040000.iommu), stream 0, compartilhado
                     com a GMU (ambos aparecem como consumer do mesmo SMMU)
  registradores .... 3 blocos: kgsl_3d0_reg_memory (0x5000000),
                     cx_mem (0x509e000), cx_dbgc (0x5061000)


2. DEVICE TREE (o que vale é o DT embutido no U-Boot)
-----------------------------------------------------
  Verificado por leitura de /proc/device-tree, não pelo .dts.

  gpu@5000000
    status ............. okay
    compatible ......... qcom,adreno-618.0, qcom,adreno
    operating-points-v2  gpu_opp_table (10 entradas declaradas)
    qcom,gmu ........... <&gmu>          (GMU como nó IRMÃO, estilo moderno)
    iommus ............. <&adreno_smmu 0 0x0>
    interconnects ...... gfx-mem (gem_noc -> mc_virt)
    nvmem-cells ........ gpu_speed_bin (qfprom 0x1a2, bits 5..12)
    zap-shader ......... memory-region = <&gpu_mem>
    #cooling-cells ..... 2
    clocks ............. AUSENTE  (correto; ver 3.2)
    power-domains ...... AUSENTE  (correto; ver 6.2)

  gmu@506a000
    clocks ............. gpu_cc_cx_gmu_clk (200 MHz), clock-names "gmu"
    power-domains ...... <&gpucc CX_GDSC>, <&gpucc GX_GDSC>

  gpucc@5090000
    compatible ......... qcom,sm7150-gpucc, qcom,sc7180-gpucc
                         (não existe gpucc-sm7150.c; o driver sc7180 atende)
    #clock-cells ....... 1     #reset-cells ... 1     #power-domain-cells 1


3. KERNEL
---------
3.1 Config (kernel 7.3, work/kernel-7.3/v4/config-7.3-hanoip)
    CONFIG_DRM_MSM=m          CONFIG_DRM_GPUVM=m       CONFIG_DRM_SCHED=m
    CONFIG_ARM_SMMU=y         CONFIG_IOMMU_SUPPORT=y
    CONFIG_PM_DEVFREQ=y       CONFIG_QCOM_GDSC=y
    CONFIG_THERMAL=y          CONFIG_QCOM_TSENS=y
    CONFIG_DMA_SHARED_BUFFER=y

3.2 Módulos e init
    msm, ubwc_config, drm_gpuvm, drm_exec, gpu_sched,
    drm_display_helper, drm_client_lib, mdt_loader
    gpu-initialized: 1    -> o ZAP shader rodou (boot seguro OK)
    hangcheck_period_ms: 250

3.3 Firmware (os corretos para A618)
    /lib/firmware/qcom/a630_sqe.fw
    /lib/firmware/qcom/a630_gmu.bin
    (a615/a616/a618/a619 compartilham a família a630 no catálogo do msm)

3.4 Por que NÃO há clock "core" no nó da GPU
    adreno_gpu.c só pede o clk "core" quando não há GMU:
      "Only handle the core clock when GMU is not in use (or is absent)."
    Em a618 com GMU a frequência é aplicada pelo FIRMWARE da GMU via HFI
    (perf level). O gpucc-sc7180.c do kernel registra só 7 clocks
    (cxo, crc_ahb, cx_gmu, cx_snoc_dvm, cxo_aon, gmu_clk_src, pll1) e o
    clk_summary mostra exatamente esses 7. O gx_gfx3d não passa pelo Linux.

3.5 Reguladores "vdd"/"vddcx" DUMMY são esperados
    dmesg: "adreno 5000000.gpu: supply vdd/vddcx not found, using dummy"
    msm_gpu.c pede esses dois (linhas 959/964) — caminho LEGADO (a3xx..a5xx).
    No a618 a tensão é votada pela GMU/firmware (RPMh), fora do alcance do
    Linux. Não é defeito e não há o que corrigir no DT.


4. DVFS / OPP
-------------
4.1 Tabela de OPPs (10 declaradas) x habilitadas (7)
    OPP (MHz)   opp-level (RPMh)          opp-supported-hw   habilitada?
    825         TURBO_L1                 0x11               NÃO
    800         TURBO                    0x19               SIM
    700         TURBO                    0x04               NÃO
    650         NOM_L1                   0x1d               SIM
    610         NOM_L1                   0x02               NÃO
    565         NOM                      0x1f               SIM
    430         SVS_L1                   0x1f               SIM
    355         SVS                      0x1f               SIM
    267         LOW_SVS                  0x1f               SIM
    180         MIN_SVS                  0x1f               SIM

    Dedução do speed bin: 800 liga com 0x19 = bits {0,3,4}; 650 liga com
    0x1d = bits {0,2,3,4}; 825 (0x11 = bits {0,4}) NÃO liga; 700 (bit 2) NÃO;
    610 (bit 1) NÃO. O único bin compatível é bin 3 -> teto real 800 MHz.
    Ou seja: 825 MHz é limitação de silício deste aparelho, não do port.

4.2 Governador e estado
    devfreq 5000000.gpu: simple_ondemand, polling_interval 16 ms
    min_freq atual 355 MHz (fixado de propósito por /usr/local/sbin/hanoip-perf-tune,
    "355 MHz floor + 16 ms" para a rolagem da UI), max 800 MHz
    trans_stat: 1392 transições; mais tempo em 800 MHz (126,9 s) e 355 (79,1 s)

4.3 Prova de que o DVFS mexe no hardware
    Fixando min=max em 180 / 355 / 800 MHz o devfreq reporta o valor pedido,
    mas o peglgears dá ~45 mil FPS nas três -> esse teste é limitado por CPU,
    não serve para provar clock. A prova válida é o comportamento observado:
    sob carga o devfreq sobe a 800 e a temperatura da GPU sobe de ~36 C para
    54,5 C; parada a carga, volta a 355. Portanto a votação de perf level
    chega ao hardware (quem aplica é a GMU, ver 3.4).


5. TÉRMICA
----------
  zonas ............. gpuss0-thermal, gpuss1-thermal
  trips ............. 95 C (passive), 110 C (critical) em ambas
  cooling device .... "devfreq-5000000.gpu", 6 estados
  medição ........... 90 s contínuos em 800 MHz (18 x peglgears):
                      pico 54,5 C, cooling 0/6 o tempo todo (zero throttling)
  folga ............. ~40 C até a primeira trip


6. ENERGIA (o item que eu tinha errado)
----------------------------------------
6.1 As GDSC da GPU EXISTEM e DESLIGAM — ciclo provado
    /sys/kernel/debug/pm_genpd/cx_gdsc   consumidores:
        5040000.iommu, genpd:0:506a000.gmu
    /sys/kernel/debug/pm_genpd/gx_gdsc   consumidores:
        genpd:1:506a000.gmu
    driver (gpucc-sc7180.c): cx_gdsc gdscr 0x106c, VOTABLE, PWRSTS_OFF_ON;
    gx_gdsc gdscr 0x100c, CLAMP_IO, PWRSTS_OFF_ON.

    Medição em repouso (4 amostras, 12 s):
        cx=off-0  gx=off-0  gpu_cc_cx_gmu_clk enable=0
    Medição sob carga (peglgears em loop):
        cx=on     gx=on     freq=800 MHz
    Medição depois da carga:
        em 4 s volta a cx=off-0 gx=off-0, com pulsos curtos "on"
        (composição da UI a 355 MHz)

    CONCLUSÃO: o colapso de trilha da GPU funciona. A medição anterior que
    dizia "ficam on" foi feita imediatamente após a carga (active_time estava
    em ~204 s), ou seja, era artefato de amostragem — mesmo tipo de erro do
    `tail` que cortou a lista de domínios.

6.2 Por que não precisa de power-domains no nó da GPU
    A GMU é o consumidor dos dois GDSC (genpd:0/1:506a000.gmu) — ela é quem
    gateia as trilhas quando o GPU fica ocioso. É o mesmo desenho do
    sm7150.dtsi do fork sm7150-mainline. Não há o que "consertar" aqui.

6.3 GMU ociosa
    gpu_cc_cx_gmu_clk e gpu_cc_gmu_clk_src: enable=0 em idle, rate 200 MHz
    quando ativa. O clock do GMU fecha junto com as trilhas.

6.4 Observação: gcc-sm7150 e sc7180-gpucc imprimem
      "sync_state() pending due to 506a000.gmu"
    O nó 506a000.gmu não tem driver próprio; ele é consumido via genpd pelo
    adreno. A mensagem é informativa e não impediu nada (clocks, GDSC, HFI e
    render funcionam). Não requer ação.


7. USERSPACE
------------
  mesa .............. 26.1.6-1 (mesa-libgallium), libdrm-freedreno
  EGL ............... 1.5, vendor "Mesa Project", driver "msm"
  OpenGL core ....... 4.6 (Core Profile), freedreno, renderer FD618, GLSL 4.60
  OpenGL compat ..... 4.6 (Compatibility Profile), FD618
  OpenGL ES ......... 3.2 Mesa 26.1.6-1, FD618
  extensões GL ...... 1331 linhas de extensões no eglinfo
  Vulkan ............ 1.3.354, "Turnip Adreno (TM) 618",
                      driverID DRIVER_ID_MESA_TURNIP,
                      deviceType INTEGRATED_GPU, deviceID 0x6010800
  ICDs .............. freedreno_icd.json presente (libvulkan_freedreno.so, 15 MB)
                      + llvmpipe (software, disponível como fallback)

  Desempenho:
    peglgears (surfaceless, sem vsync) .... 40.868 FPS (5,1 s, 207.520 frames)
    vkgears -size 800x1400 na sessão Phosh  60,0 FPS estáveis (vsync de 60 Hz)
    obs: em outra amostra o peglgears deu ~45 mil FPS; a diferença é ruído de
    CPU/submissão, não de GPU.

  Nós de dispositivo:
    /dev/dri/renderD128  crw-rw----+ root:render  (ACL por grupo render)
    /dev/dri/card0       DRIVER=msm_dpu, OF qcom,sm7150-dpu


8. O QUE NÃO FOI TESTADO (honestidade do levantamento)
------------------------------------------------------
  a) GPU através de suspend/resume (s2idle). O sistema suspende e volta
     (LEVANTAMENTO-CPU-100), mas não rodei carga de GPU antes/depois de um
     ciclo para provar que o contexto volta.
  b) Caminho de FALHA (hangcheck / coredump / recovery). Não há contador
     /sys/kernel/debug/dri/0/fault neste kernel e não provoquei fault.
  c) Recursos de DRM/MSM expostos por ioctl (VM_BIND, preempção, prio de
     contexto) — não consultei MSM_PARAM; o que foi provado é o que está em 7.
  d) Decode de vídeo (Venus) não faz parte da GPU e não foi tocado aqui.


9. PENDÊNCIAS REAIS (curtas)
----------------------------
  1. Testar GPU antes/depois de um s2idle (item 8a) — é o único buraco de
     cobertura de GPU que sobrou. Não exige rebuild.
  2. Opcional: baixar o piso de 355 -> 180 MHz com a tela apagada, para
     economia em idle (escolha de política, não bug).
  3. Limpar o spam "disallowed SPMI write to sid=0, addr=0x6046" removendo
     allow-set-time do &pm6150_rtc no DT (o offset de RTC em userspace já
     resolve o relógio). Isso é RTC, não GPU, mas polui o dmesg.


10. COMANDOS PARA REPETIR ESTA VARREDURA
----------------------------------------
  Identidade:
    head -3 /sys/kernel/debug/dri/0/gpu
    grep -E "adreno" /proc/device-tree/soc@0/gpu@5000000/compatible | tr '\0' ' '
  APIs:
    EGL_PLATFORM=surfaceless eglinfo | grep -E "core profile|ES profile"
    XDG_RUNTIME_DIR=/run/user/1000 vulkaninfo --summary | grep -E "deviceName|apiVersion"
  DVFS/térmica:
    cat /sys/class/devfreq/5000000.gpu/{cur_freq,min_freq,max_freq,governor,trans_stat}
    for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = gpuss0-thermal ] && cat $z/temp; done
  Energia (o teste que importa):
    cat /sys/kernel/debug/pm_genpd/{cx_gdsc,gx_gdsc}/current_state
    (ocioso deve dar off-0; durante carga, on)
  Carga:
    EGL_PLATFORM=surfaceless peglgears
    runuser -u kali -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 vkgears -size 800x1400

  ATENÇÃO: NÃO fazer `cat /sys/kernel/debug/dri/0/gpu` nem `.../mm` sem
  filtrar — eles despejam buffers em ascii85 e travam a sessão SSH.
