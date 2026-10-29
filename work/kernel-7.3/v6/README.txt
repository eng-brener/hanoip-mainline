Kernel 7.3 hanoip — v6: v5 + câmeras (29/10/2026)
===================================================

Base: upstream v7.3 (árvore 30fd2ef8). patches/ = 194 commits, `git am`
direto sobre v7.3. Árvore resultante f4dccdc7 (conferida pelo
build-inside.sh e gravada em /src/obj/.tree-v6). Branch hanoip-7.3-v6 no
volume hanoip-kernel73-v3-src.

  0001-0189  idênticos ao v5 (árvore 2df2c4d6 = kernel #29 do
             PRE-GOLD-20261028-1707).
  0190  media: qcom: camss: roll back started subdevices when stream start
        fails (subdevs já iniciados param em ordem inversa).
  0191  media: qcom: camss: sm7150: give every CSIPHY the stock clock set
        (cphy_rx 400 MHz + csiphy0 + csiphyN + timer 300 MHz nos 4 PHY;
        sem isso o PHY1/PHY3 não entregavam frame).
  0192  media: qcom: camss: sm7150: add C-PHY receive and bring-up
        diagnostics (S5KHM2 = C-PHY 3 trios; tabela csiphy_3ph_v1_2 do
        vendor; params cphy_settle_cnt, dphy_settle, lane_map, phy_status).
  0193  i2c: qcom-cci: reset the controller on runtime resume (fim do
        timeout intermitente "master N queue 0 timeout": 9/9, 0 timeouts).
  0194  media: i2c: add Motorola hanoip camera sensor and VCM drivers
        (s5k4h7, hanoip-cam = OV32B + S5KHM2, hanoip-vcm).

config-7.3-hanoip = v5 + CONFIG_VIDEO_HANOIP_{S5K4H7,CAM,VCM}=m (posição
canônica do olddefconfig). Tudo o que mudou é MÓDULO (=m): o Image tem o
mesmo código do v5/#29.

Validado no aparelho (29/10), com estes mesmos fontes compilados fora da
árvore contra o #29: S5K4H7 traseira wide, S5KHM2 traseira principal
4000x3000 (C-PHY) e OV32B frontal no Snapshot (libcamera 0.7.2 do
sistema), troca entre as três, cores certas (Bayer GRBG/GBRG/BGGR), foco
das duas traseiras pelos nós de lente. O DT vem do U-Boot cam-tres
(uboot-sm7150/.../sm7150-motorola-hanoip-cam-tres.dts). Detalhes:
docs/kernel/checkpoint-2026-10-28-camera.txt, itens 7-18.

A OV02B1B (profundidade) não entra no app por decisão do usuário; o
driver dela (work/cameras-20261028/ov02b1b-*) não está aqui.

Construir: ./build.sh (mesma imagem docker e volume do v3/v4/v5).
