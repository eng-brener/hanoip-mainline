// SPDX-License-Identifier: GPL-2.0-only
/*
 * gk-probe - sondagem do caminho Keymaster -> listener RPMB, SEM escrita.
 *
 * Manda UM GK_NEW_VERIFY (0x21002) ao keymaster64 residente, no formato do
 * gatekeeper HAL da Qualcomm (GatekeeperHalDevice::verify +
 * GatekeeperSerialize::serializeClientVerify + KeymasterUtils::sendCmd,
 * desmontados em work/fingerprint-20261029/gatekeeper-offline/):
 *
 *   pedido   [u32 cmd][CBOR {3: uid, 4: challenge, 6: h'handle', 9: h'senha'}]
 *   resposta [u32 status][u32 len][CBOR]   (no múltiplo de 4 após o pedido)
 *
 * Os comandos legados GK_SB_* (0x150x) caem em stubs -10008 neste firmware.
 *
 * O handle (58 B, o tamanho que o TA exige) é zerado e a senha é falsa, para
 * um uid que o Android não usa: o objetivo é só fazer o TA ler o registro do
 * usuário no armazenamento seguro e observar os pedidos RPMB no dmesg. O
 * módulo recusa toda escrita RPMB (rpmb_writes=0); este programa se recusa a
 * rodar se o parâmetro estiver ligado.
 *
 * Nunca imprime o corpo da resposta (poderia conter um token).
 */
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "qseecom-fpc.h"

#define GK_NEW_VERIFY		0x21002
#define GK_HANDLE_LEN		58	/* o TA exige exatamente 0x3a */
#define PROBE_UID		0x4b414c49u	/* "KALI": não é um usuário Android */
#define RSP_LEN			0x8000

static int rpmb_writes_on(void)
{
	FILE *f = fopen("/sys/module/qcom_qseecom_fpc/parameters/rpmb_writes",
			"r");
	int c;

	if (!f)
		return -1;
	c = fgetc(f);
	fclose(f);
	return c == 'Y' || c == '1';
}

/* Cabeçalho CBOR: tipo maior + argumento na forma mínima. */
static size_t cbor_head(uint8_t *p, uint8_t major, uint64_t v)
{
	int n, i;

	if (v < 24) {
		p[0] = major << 5 | v;
		return 1;
	}
	n = v <= 0xff ? 1 : v <= 0xffff ? 2 : v <= 0xffffffffu ? 4 : 8;
	p[0] = major << 5 | (n == 1 ? 24 : n == 2 ? 25 : n == 4 ? 26 : 27);
	for (i = 0; i < n; i++)
		p[1 + i] = v >> (8 * (n - 1 - i));
	return 1 + n;
}

static size_t cbor_bytes(uint8_t *p, const void *b, size_t len)
{
	size_t n = cbor_head(p, 2, len);

	memcpy(p + n, b, len);
	return n + len;
}

int main(void)
{
	static const char senha[] = "sonda-sem-escrita";
	static const uint8_t handle[GK_HANDLE_LEN];
	struct qseecom_fpc_app_id id = { .name = "keymaster64" };
	struct qseecom_fpc_send_raw arg = { 0 };
	uint8_t req[256], *p;
	uint32_t cmd = GK_NEW_VERIFY, *rsp;
	int fd, w;

	w = rpmb_writes_on();
	if (w != 0) {
		fprintf(stderr, "recusado: rpmb_writes %s\n",
			w < 0 ? "ilegível (módulo carregado?)" : "LIGADO");
		return 2;
	}

	fd = open("/dev/qseecom-fpc", O_RDWR);
	if (fd < 0) {
		perror("/dev/qseecom-fpc");
		return 1;
	}
	if (ioctl(fd, QSEECOM_FPC_GET_APP_ID, &id)) {
		perror("GET_APP_ID keymaster64");
		return 1;
	}
	printf("keymaster64 app_id %u\n", id.app_id);

	memcpy(req, &cmd, 4);
	p = req + 4;
	p += cbor_head(p, 5, 4);		/* mapa de 4 pares */
	p += cbor_head(p, 0, 3);
	p += cbor_head(p, 0, PROBE_UID);	/* 3: uid */
	p += cbor_head(p, 0, 4);
	p += cbor_head(p, 0, 0);		/* 4: challenge */
	p += cbor_head(p, 0, 6);
	p += cbor_bytes(p, handle, sizeof(handle));	/* 6: handle */
	p += cbor_head(p, 0, 9);
	p += cbor_bytes(p, senha, sizeof(senha) - 1);	/* 9: senha */

	rsp = calloc(1, RSP_LEN);
	if (!rsp)
		return 1;
	arg.req = (uintptr_t)req;
	arg.req_len = p - req;
	arg.rsp = (uintptr_t)rsp;
	arg.rsp_len = RSP_LEN;
	arg.app_id = id.app_id;

	if (ioctl(fd, QSEECOM_FPC_SEND_RAW, &arg)) {
		printf("SEND_RAW: %s (errno %d)\n", strerror(errno), errno);
		return 1;
	}
	printf("resposta: status %d (%#x) len %u (corpo não exibido)\n",
	       (int32_t)rsp[0], rsp[0], rsp[1]);
	free(rsp);
	close(fd);
	return 0;
}
