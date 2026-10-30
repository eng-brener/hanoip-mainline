/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Cliente mínimo do Gatekeeper do keymaster64 (QSEE), para obter um HAT
 * legítimo que autorize o cadastro no fpctzapp.
 *
 * Formato (desmontado do gatekeeper HAL da Qualcomm, ver
 * work/fingerprint-20261029/gatekeeper-offline/ e HANDOFF-20261030.md):
 *   pedido   [u32 cmd][CBOR mapa]
 *   resposta [u32 status][u32 len][CBOR mapa]  (no múltiplo de 4 seguinte)
 *   GK_NEW_ENROLL 0x21001: {3: uid, [5: handle, 7: senha atual,] 8: senha}
 *                          -> {6: handle de 58 B}
 *   GK_NEW_VERIFY 0x21002: {3: uid, 4: challenge, 6: handle, 9: senha}
 *                          -> {11: versão, 4: challenge, 12: user_id,
 *                              13: authenticator_id, 14: tipo,
 *                              15: timestamp, 16: hmac(32)}
 *   KM 0x205 GET_AUTH_TOKEN_KEY (binário): req {0x205, 2}, rsp {status,
 *                          off, len} com o blob encapsulado para o fpctzapp.
 *
 * A credencial é um segredo da MÁQUINA (32 B aleatórios em
 * /var/lib/fpc-gk/secret), num uid que o Android não usa (0x4b414c49), e
 * nunca é impressa. Escreve no RPMB através do listener do módulo.
 */
#ifndef FPC_GK_CLIENT_H
#define FPC_GK_CLIENT_H

#include <sys/stat.h>

#define GK_NEW_ENROLL		0x21001
#define GK_NEW_VERIFY		0x21002
#define KM_GET_AUTH_TOKEN_KEY	0x205
#define GK_UID			0x4b414c49u	/* "KALI" */
#define GK_HANDLE_LEN		58
#define GK_SECRET_LEN		32
#define GK_HAT_LEN		69
#define GK_DIR			"/var/lib/fpc-gk"
#define GK_RSP_LEN		0x8000

static uint32_t g_km_app_id;

/* ------------------------------------------------------------ CBOR mínimo */

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

static size_t cbor_uint_kv(uint8_t *p, uint64_t k, uint64_t v)
{
	size_t n = cbor_head(p, 0, k);

	return n + cbor_head(p + n, 0, v);
}

static size_t cbor_bytes_kv(uint8_t *p, uint64_t k, const void *b, size_t len)
{
	size_t n = cbor_head(p, 0, k);

	n += cbor_head(p + n, 2, len);
	memcpy(p + n, b, len);
	return n + len;
}

/* Lê um cabeçalho; devolve bytes consumidos ou 0 em erro. */
static size_t cbor_read_head(const uint8_t *p, size_t len, uint8_t *major,
			     uint64_t *v)
{
	uint8_t ai;
	size_t n, i;

	if (!len)
		return 0;
	*major = p[0] >> 5;
	ai = p[0] & 0x1f;
	if (ai < 24) {
		*v = ai;
		return 1;
	}
	if (ai > 27)
		return 0;	/* sem tamanho indefinido aqui */
	n = (size_t)1 << (ai - 24);
	if (len < 1 + n)
		return 0;
	*v = 0;
	for (i = 0; i < n; i++)
		*v = *v << 8 | p[1 + i];
	return 1 + n;
}

/* Pula um item inteiro (com filhos); devolve bytes ou 0 em erro. */
static size_t cbor_skip(const uint8_t *p, size_t len, int depth)
{
	uint8_t major;
	uint64_t v, i;
	size_t n = cbor_read_head(p, len, &major, &v), m;

	if (!n || depth > 8)
		return 0;
	switch (major) {
	case 0: case 1: case 7:
		return n;
	case 2: case 3:
		return v <= len - n ? n + v : 0;
	case 4: case 5:
		for (i = 0; i < (major == 5 ? 2 * v : v); i++) {
			m = cbor_skip(p + n, len - n, depth + 1);
			if (!m)
				return 0;
			n += m;
		}
		return n;
	case 6:
		m = cbor_skip(p + n, len - n, depth + 1);
		return m ? n + m : 0;
	}
	return 0;
}

/*
 * Procura a chave inteira @key num mapa CBOR. Devolve 0 e preenche @u (uint)
 * ou @b/@blen (bstr); -1 se não achar ou se o CBOR for inválido.
 */
static int cbor_map_get(const uint8_t *p, size_t len, uint64_t key,
			uint64_t *u, const uint8_t **b, size_t *blen)
{
	uint8_t major;
	uint64_t count, k, v, i;
	size_t n = cbor_read_head(p, len, &major, &count), m;

	if (!n || major != 5)
		return -1;
	for (i = 0; i < count; i++) {
		m = cbor_read_head(p + n, len - n, &major, &k);
		if (!m || major != 0)
			return -1;
		n += m;
		if (k == key) {
			m = cbor_read_head(p + n, len - n, &major, &v);
			if (!m)
				return -1;
			if (major == 0 && u) {
				*u = v;
				return 0;
			}
			if (major == 2 && b && v <= len - n - m) {
				*b = p + n + m;
				*blen = v;
				return 0;
			}
			return -1;
		}
		m = cbor_skip(p + n, len - n, 0);
		if (!m)
			return -1;
		n += m;
	}
	return -1;
}

/* ------------------------------------------------------------ transporte */

static int km_app_id(void)
{
	struct qseecom_fpc_app_id id = { .name = "keymaster64" };

	if (g_km_app_id)
		return 0;
	if (ioctl(tac.fd, QSEECOM_FPC_GET_APP_ID, &id)) {
		fprintf(stderr, "keymaster64 não encontrado: %s\n",
			strerror(errno));
		return -1;
	}
	g_km_app_id = id.app_id;
	return 0;
}

/* Envia ao keymaster; @rsp recebe a resposta inteira (GK_RSP_LEN bytes). */
static int km_send(const void *req, size_t req_len, uint8_t *rsp)
{
	struct qseecom_fpc_send_raw arg = {
		.req = (uintptr_t)req,
		.req_len = (uint32_t)req_len,
		.rsp = (uintptr_t)rsp,
		.rsp_len = GK_RSP_LEN,
	};

	if (km_app_id())
		return -1;
	arg.app_id = g_km_app_id;
	memset(rsp, 0, GK_RSP_LEN);
	if (ioctl(tac.fd, QSEECOM_FPC_SEND_RAW, &arg)) {
		fprintf(stderr, "keymaster: %s\n", strerror(errno));
		return -1;
	}
	return 0;
}

/* Comando GK em CBOR; devolve o mapa da resposta em @map/@map_len. */
static int gk_call(uint32_t cmd, const uint8_t *cbor, size_t cbor_len,
		   uint8_t *rsp, const uint8_t **map, size_t *map_len)
{
	uint8_t req[512];
	int32_t status;
	uint32_t len;

	if (cbor_len + 4 > sizeof(req))
		return -1;
	memcpy(req, &cmd, 4);
	memcpy(req + 4, cbor, cbor_len);
	if (km_send(req, cbor_len + 4, rsp)) {
		explicit_bzero(req, sizeof(req));
		return -1;
	}
	explicit_bzero(req, sizeof(req));
	memcpy(&status, rsp, 4);
	memcpy(&len, rsp + 4, 4);
	if (status) {
		fprintf(stderr, "gatekeeper %#x: status %d\n", cmd, status);
		return -1;
	}
	if (len > GK_RSP_LEN - 8) {
		fprintf(stderr, "gatekeeper %#x: tamanho %u inválido\n", cmd, len);
		return -1;
	}
	*map = rsp + 8;
	*map_len = len;
	return 0;
}

/* ------------------------------------------------------------ arquivos */

static int gk_read_exact(const char *name, void *buf, size_t len)
{
	char path[128];
	int fd;
	ssize_t r;

	snprintf(path, sizeof(path), GK_DIR "/%s", name);
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -1;
	r = read(fd, buf, len);
	close(fd);
	return r == (ssize_t)len ? 0 : -1;
}

static int gk_write_exact(const char *name, const void *buf, size_t len)
{
	char path[128], tmp[136];
	int fd;
	ssize_t w;

	snprintf(path, sizeof(path), GK_DIR "/%s", name);
	snprintf(tmp, sizeof(tmp), "%s.new", path);
	fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
	if (fd < 0)
		return -1;
	w = write(fd, buf, len);
	if (w != (ssize_t)len || fsync(fd)) {
		close(fd);
		unlink(tmp);
		return -1;
	}
	close(fd);
	return rename(tmp, path);
}

/* ------------------------------------------------------------ operações */

/*
 * Garante segredo + handle. Cadastra no Gatekeeper só na primeira vez; o
 * handle volta do TEE e fica no disco (sem ele a senha não serve).
 */
static int gk_ensure_enrolled(uint8_t *secret, uint8_t *handle)
{
	uint8_t cbor[128], *p = cbor, *rsp;
	const uint8_t *map, *h;
	size_t map_len, hlen;
	int fd, ret = -1;

	if (!gk_read_exact("secret", secret, GK_SECRET_LEN) &&
	    !gk_read_exact("handle", handle, GK_HANDLE_LEN)) {
		printf("gatekeeper: credencial da máquina já cadastrada\n");
		return 0;
	}

	if (mkdir(GK_DIR, 0700) && errno != EEXIST) {
		fprintf(stderr, GK_DIR ": %s\n", strerror(errno));
		return -1;
	}
	fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
	if (fd < 0 || read(fd, secret, GK_SECRET_LEN) != GK_SECRET_LEN) {
		fprintf(stderr, "sem /dev/urandom\n");
		if (fd >= 0)
			close(fd);
		return -1;
	}
	close(fd);
	/* O segredo vai para o disco ANTES do cadastro, para nunca se perder. */
	if (gk_write_exact("secret", secret, GK_SECRET_LEN)) {
		fprintf(stderr, "não gravou " GK_DIR "/secret\n");
		return -1;
	}

	p += cbor_head(p, 5, 2);
	p += cbor_uint_kv(p, 3, GK_UID);
	p += cbor_bytes_kv(p, 8, secret, GK_SECRET_LEN);

	rsp = calloc(1, GK_RSP_LEN);
	if (!rsp)
		return -1;
	printf("gatekeeper: cadastrando credencial da máquina (uid %#x)\n",
	       GK_UID);
	if (gk_call(GK_NEW_ENROLL, cbor, p - cbor, rsp, &map, &map_len))
		goto out;
	if (cbor_map_get(map, map_len, 6, NULL, &h, &hlen) ||
	    hlen != GK_HANDLE_LEN) {
		fprintf(stderr, "gatekeeper: resposta do enroll sem handle\n");
		goto out;
	}
	memcpy(handle, h, GK_HANDLE_LEN);
	if (gk_write_exact("handle", handle, GK_HANDLE_LEN)) {
		fprintf(stderr, "não gravou " GK_DIR "/handle\n");
		goto out;
	}
	printf("gatekeeper: cadastrado; handle em " GK_DIR "/handle\n");
	ret = 0;
out:
	explicit_bzero(cbor, sizeof(cbor));
	explicit_bzero(rsp, GK_RSP_LEN);
	free(rsp);
	return ret;
}

/* Verifica a credencial com o desafio do FPC e monta o HAT de 69 B. */
static int gk_verify_hat(uint64_t challenge, uint8_t *hat)
{
	uint8_t secret[GK_SECRET_LEN], handle[GK_HANDLE_LEN];
	uint8_t cbor[256], *p = cbor, *rsp;
	const uint8_t *map, *mac;
	size_t map_len, mac_len;
	uint64_t ver, ch, uid, aid, type, ts;
	int ret = -1;

	if (gk_ensure_enrolled(secret, handle))
		return -1;

	p += cbor_head(p, 5, 4);
	p += cbor_uint_kv(p, 3, GK_UID);
	p += cbor_uint_kv(p, 4, challenge);
	p += cbor_bytes_kv(p, 6, handle, GK_HANDLE_LEN);
	p += cbor_bytes_kv(p, 9, secret, GK_SECRET_LEN);
	explicit_bzero(secret, sizeof(secret));

	rsp = calloc(1, GK_RSP_LEN);
	if (!rsp)
		goto out;
	if (gk_call(GK_NEW_VERIFY, cbor, p - cbor, rsp, &map, &map_len))
		goto out;
	if (cbor_map_get(map, map_len, 11, &ver, NULL, NULL) ||
	    cbor_map_get(map, map_len, 4, &ch, NULL, NULL) ||
	    cbor_map_get(map, map_len, 12, &uid, NULL, NULL) ||
	    cbor_map_get(map, map_len, 13, &aid, NULL, NULL) ||
	    cbor_map_get(map, map_len, 14, &type, NULL, NULL) ||
	    cbor_map_get(map, map_len, 15, &ts, NULL, NULL) ||
	    cbor_map_get(map, map_len, 16, NULL, &mac, &mac_len) ||
	    mac_len != 32) {
		fprintf(stderr, "gatekeeper: resposta do verify incompleta\n");
		goto out;
	}
	if (ch != challenge) {
		fprintf(stderr, "gatekeeper: desafio do token não confere\n");
		goto out;
	}
	/* Mesma montagem do HAL: inteiros copiados como estão (LE). */
	hat[0] = (uint8_t)ver;
	memcpy(hat + 1, &ch, 8);
	memcpy(hat + 9, &uid, 8);
	memcpy(hat + 17, &aid, 8);
	{
		uint32_t t32 = (uint32_t)type;

		memcpy(hat + 25, &t32, 4);
	}
	memcpy(hat + 29, &ts, 8);
	memcpy(hat + 37, mac, 32);
	printf("gatekeeper: token emitido (versão %u, %u bytes; conteúdo omitido)\n",
	       (unsigned)ver, GK_HAT_LEN);
	ret = 0;
out:
	explicit_bzero(cbor, sizeof(cbor));
	explicit_bzero(handle, sizeof(handle));
	if (rsp) {
		explicit_bzero(rsp, GK_RSP_LEN);
		free(rsp);
	}
	return ret;
}

/* Keymaster 0x205 -> fpctzapp módulo 3 cmd 5 (chave HMAC dos tokens). */
static int fpc_hw_auth_init(void)
{
	uint32_t req[16] = { KM_GET_AUTH_TOKEN_KEY, 2 };
	uint8_t *rsp, *b;
	uint32_t status, off, len;
	int64_t r = 0;
	int ret = -1;

	rsp = calloc(1, GK_RSP_LEN);
	b = frame_alloc(0x1000);
	if (!rsp || km_send(req, sizeof(req), rsp))
		goto out;
	memcpy(&status, rsp, 4);
	memcpy(&off, rsp + 4, 4);
	memcpy(&len, rsp + 8, 4);
	if (status || off < 12 || !len || off > 0x3c0 || len > 0x3c0 - off ||
	    len > 0x1000 - 0xc) {
		fprintf(stderr, "keymaster 0x205: status %d off %u len %u\n",
			(int32_t)status, off, len);
		goto out;
	}
	*(uint32_t *)(b + 8) = len;
	memcpy(b + 0xc, rsp + off, len);
	if (ta_send(3, 5, b, 0x1000, &r) || r) {
		fprintf(stderr, "init_hw_auth no TA falhou\n");
		goto out;
	}
	printf("hw_auth: chave do keymaster carregada no TA\n");
	ret = 0;
out:
	if (rsp) {
		explicit_bzero(rsp, GK_RSP_LEN);
		free(rsp);
	}
	explicit_bzero(b, 0x1000);
	free(b);
	return ret;
}

/*
 * Autoriza um cadastro: desafio do TA (m3 c2) -> verify no Gatekeeper ->
 * HAT -> authorize_enrol (m3 c3).
 */
static int fpc_authorize_enrol(void)
{
	uint8_t *b = frame_alloc(0x70), hat[GK_HAT_LEN];
	uint64_t challenge = 0;
	int64_t r = 0;
	int ret = -1;

	if (fpc_hw_auth_init())
		goto out;
	if (ta_send(3, 2, b, 0x70, &r) || r) {
		fprintf(stderr, "desafio do cadastro falhou\n");
		goto out;
	}
	memcpy(&challenge, b + 8, 8);
	if (!challenge) {
		fprintf(stderr, "desafio zero\n");
		goto out;
	}
	if (gk_verify_hat(challenge, hat))
		goto out;

	memset(b, 0, 0x70);
	*(uint32_t *)(b + 8) = GK_HAT_LEN;
	memcpy(b + 0xc, hat, GK_HAT_LEN);
	if (ta_send(3, 3, b, 0x70, &r) || r) {
		fprintf(stderr, "authorize_enrol recusou o token\n");
		goto out;
	}
	printf("cadastro autorizado pelo token do gatekeeper\n");
	ret = 0;
out:
	explicit_bzero(hat, sizeof(hat));
	explicit_bzero(b, 0x70);
	free(b);
	return ret;
}

#endif
