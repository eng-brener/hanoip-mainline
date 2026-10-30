// SPDX-License-Identifier: GPL-2.0-only
/*
 * fpc-tac - userspace client for the FPC fingerprint TA (fpctzapp) on the
 * Motorola hanoip, through /dev/qseecom-fpc.
 *
 * Protocol reference (all offsets below were decoded statically from the
 * shipped TA/HAL, see docs/kernel/PROTOCOLO-FPC-TA-20261029.md):
 *
 *   frame[0]  = module id    frame[1]  = command id
 *   module 12: +0x14 limit (in), +0x14 len / +0x18 payload (out)
 *   module 10: +8 flags, +0xc mode, +0x10 out, +0x14 limit
 *   module 11: +8 in/out value
 *   module 4 : +8 size, +0xc mode/offset, +0x10 total, payload at +0xc
 *
 * Nothing here writes to the phone's storage; the template database is a plain
 * file path the caller chooses.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <linux/gpio.h>
#include <poll.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "qseecom-fpc.h"

#define DIE(...) do { fprintf(stderr, __VA_ARGS__); fputc('\n', stderr); exit(1); } while (0)

/* Erros que o roteador do TA devolve quando algo é recusado. */
#define TA_ERR_BAD_ARG		0xE8A1C0A1u
#define TA_ERR_CMD		0xE8A1C0CEu
#define TA_ERR_SENSOR_BASE	0xE8A1017Bu

struct tac {
	int fd;
	uint8_t *frame;
	size_t frame_len;
	int app_loaded;
};

static struct tac tac;
static int g_irq_fd = -1;
static uint32_t g_app_id;	/* 0 = usa o app carregado pelo driver */
static int32_t g_last_status;	/* rsp[0] da última chamada = retorno do TA */

/* ---------------------------------------------------------------- utilidades */

static void hexdump(const char *tag, const uint8_t *p, size_t n)
{
	printf("%s (%zu bytes):", tag, n);
	for (size_t i = 0; i < n; i++) {
		if (i % 16 == 0)
			printf("\n  %04zx: ", i);
		printf("%02x ", p[i]);
	}
	printf("\n");
}

static int ta_send(uint32_t module, uint32_t cmd, void *buf, size_t len,
		   int64_t *ta_result)
{
	struct qseecom_fpc_send arg = {
		.req = (uint64_t)(uintptr_t)tac.frame,
		.frame = (uint64_t)(uintptr_t)buf,
		.frame_len = (uint32_t)len,
		.app_id = g_app_id,
		.status = (int32_t)0xaaaaaaaa,
	};
	uint8_t req[QSEECOM_FPC_CTRL_LEN], rsp[QSEECOM_FPC_RSP_LEN];
	int ret;

	if (len > tac.frame_len)
		DIE("frame de %zu bytes maior que o buffer (%zu)", len, tac.frame_len);
	if (len < 8)
		DIE("frame curto demais");

	*(uint32_t *)buf = module;
	*(uint32_t *)((uint8_t *)buf + 4) = cmd;

	arg.req = (uint64_t)(uintptr_t)req;
	arg.rsp = (uint64_t)(uintptr_t)rsp;

	ret = ioctl(tac.fd, QSEECOM_FPC_SEND, &arg);
	if (getenv("FPC_TAC_DUMP")) {
		printf("  send m%u c%u flen=%zu ret=%d status=%d ta_result=%lld\n",
		       module, cmd, len, ret, arg.status,
		       (long long)arg.ta_result);
		hexdump("  out[0..0x40]", buf, len < 0x40 ? len : 0x40);
		hexdump("  ctrl (volta do driver)", req, 0x40);
		hexdump("  rsp", rsp, 0x20);
	}
	if (ret < 0) {
		int saved_errno = errno;
		fprintf(stderr, "SEND module %u cmd %u: %s\n", module, cmd,
			strerror(saved_errno));
		return -saved_errno;
	}
	if (ta_result)
		*ta_result = arg.ta_result;
	g_last_status = arg.status;
	if ((uint32_t)arg.status == 0xaaaaaaaau) {
		fprintf(stderr, "Driver não devolveu o status do TA; resultado inválido\n");
		return -EIO;
	}
	/* Sensor commands 1 and 4 return nonnegative state values, not just 0. */
	if (arg.status != 0 && !(module == 10 && (cmd == 1 || cmd == 4) &&
				 arg.status > 0 && arg.status <= 3) &&
	    !(module == 11 && cmd == 2 &&
	      (arg.status == 6 || arg.status == 8))) {
		fprintf(stderr, "TA module %u cmd %u: status=0x%08x (SCM result=%lld)\n",
			module, cmd, (uint32_t)arg.status, (long long)arg.ta_result);
		return -EIO;
	}
	return 0;
}

static const char *ta_strerror(int64_t r)
{
	static char b[64];

	if (r >= 0 && r < 0x10000)
		return NULL;		/* contagem/valor, não erro */
	switch ((uint32_t)r) {
	case TA_ERR_BAD_ARG: return "TA: argumento inválido/tamanho curto";
	case TA_ERR_CMD: return "TA: comando não suportado";
	}
	snprintf(b, sizeof(b), "TA: 0x%08x", (uint32_t)r);
	return b;
}

/* ------------------------------------------------------------------- QSEECOM */

static int read_file(const char *path, uint8_t **out, size_t *len)
{
	struct stat st;
	uint8_t *p;
	int fd = open(path, O_RDONLY);

	if (fd < 0)
		return -1;
	if (fstat(fd, &st)) {
		close(fd);
		return -1;
	}
	p = malloc(st.st_size);
	if (!p || read(fd, p, st.st_size) != st.st_size) {
		free(p);
		close(fd);
		return -1;
	}
	close(fd);
	*out = p;
	*len = st.st_size;
	return 0;
}

static void load_app(const char *fwdir)
{
	/*
	 * A imagem que o TEE espera é [.mdt][b00][b01]... — o .mdt primeiro,
	 * seguido dos segmentos, com mdt_len = tamanho do .mdt e img_len = total.
	 * (Confirmado em drivers/misc/qseecom.c do Android:
	 *  __qseecom_get_fw_data copia o .mdt e depois concatena os bXX.)
	 */
	char path[512];
	uint8_t *img = NULL, *seg;
	size_t total = 0, mdt_len = 0;
	struct qseecom_fpc_load arg;
	int ret;

	snprintf(path, sizeof(path), "%s/fpctzapp.mdt", fwdir);
	if (read_file(path, &seg, &mdt_len))
		DIE("não consegui ler %s", path);
	img = seg;
	total = mdt_len;

	for (int i = 0; i < 16; i++) {
		size_t n;

		snprintf(path, sizeof(path), "%s/fpctzapp.b%02d", fwdir, i);
		if (read_file(path, &seg, &n))
			break;
		img = realloc(img, total + n);
		if (!img)
			DIE("sem memória");
		memcpy(img + total, seg, n);
		total += n;
		free(seg);
	}
	if (total == mdt_len)
		DIE("nenhum segmento fpctzapp.bXX em %s", fwdir);

	arg.image = (uint64_t)(uintptr_t)img;
	arg.image_len = (uint32_t)total;
	arg.mdt_len = (uint32_t)mdt_len;
	arg.app_id = 0;
	arg.reserved = 0;

	ret = ioctl(tac.fd, QSEECOM_FPC_LOAD_APP, &arg);
	free(img);
	if (ret < 0) {
		if (errno == EIO)
			DIE("o TEE recusou o TA (assinatura/permissão). mdt=%zu img=%zu",
			    mdt_len, total);
		DIE("LOAD_APP: %s", strerror(errno));
	}
	tac.app_loaded = 1;
	printf("TA carregado: %zu bytes (mdt %zu), app_id %u\n", total, mdt_len,
	       arg.app_id);
}

/* ---------------------------------------------------------------------- GPIO */

static int gpio_chip_fd(const char *path)
{
	int fd = open(path, O_RDWR);

	if (fd < 0)
		DIE("gpiochip %s: %s", path, strerror(errno));
	return fd;
}

static void gpio_out_set(int fd, uint64_t mask, uint64_t bits);

static int gpio_out_request(const char *path, unsigned enable, unsigned reset)
{
	struct gpio_v2_line_request req = { 0 };
	uint64_t vals = 0;
	int chip, fd;

	chip = gpio_chip_fd(path);
	req.num_lines = 2;
	req.offsets[0] = enable;
	req.offsets[1] = reset;
	snprintf(req.consumer, sizeof(req.consumer), "fpc-tac");
	req.config.flags = GPIO_V2_LINE_FLAG_OUTPUT;
	req.config.num_attrs = 1;
	req.config.attrs[0].attr.id = GPIO_V2_LINE_ATTR_ID_OUTPUT_VALUES;
	req.config.attrs[0].attr.values = vals;
	req.config.attrs[0].mask = 0x3;

	if (ioctl(chip, GPIO_V2_GET_LINE_IOCTL, &req) < 0)
		DIE("gpio request (out %u/%u): %s", enable, reset, strerror(errno));
	close(chip);
	fd = req.fd;

	/* enable ligado, reset ainda assertado: o pulso é feito pelo chamador */
	gpio_out_set(fd, 0x3, 0x1);
	return fd;
}

static void gpio_out_set(int fd, uint64_t mask, uint64_t bits)
{
	struct gpio_v2_line_values v = { .bits = bits, .mask = mask };

	if (ioctl(fd, GPIO_V2_LINE_SET_VALUES_IOCTL, &v) < 0)
		DIE("gpio set: %s", strerror(errno));
}

static int gpio_edge_request(const char *path, unsigned line)
{
	struct gpio_v2_line_request req = { 0 };
	int chip;

	chip = gpio_chip_fd(path);
	req.num_lines = 1;
	req.event_buffer_size = 16;
	req.offsets[0] = line;
	snprintf(req.consumer, sizeof(req.consumer), "fpc-tac");
	req.config.flags = GPIO_V2_LINE_FLAG_INPUT |
			   GPIO_V2_LINE_FLAG_EDGE_RISING |
			   GPIO_V2_LINE_FLAG_BIAS_PULL_DOWN;
	if (ioctl(chip, GPIO_V2_GET_LINE_IOCTL, &req) < 0)
		DIE("gpio request (irq %u): %s", line, strerror(errno));
	close(chip);
	return req.fd;
}

static int gpio_wait_edge(int fd, int timeout_ms)
{
	struct gpio_v2_line_event ev;
	struct pollfd pfd = { .fd = fd, .events = POLLIN };

	if (poll(&pfd, 1, timeout_ms) <= 0)
		return -1;
	return read(fd, &ev, sizeof(ev)) == sizeof(ev) ? ev.timestamp_ns > 0 : -1;
}

/* Discard events queued during setup; these are not evidence of a new touch. */
static int gpio_discard_pending(int fd)
{
	struct gpio_v2_line_event ev;
	struct pollfd pfd = { .fd = fd, .events = POLLIN };
	int count = 0;

	while (poll(&pfd, 1, 0) > 0 && (pfd.revents & POLLIN)) {
		if (read(fd, &ev, sizeof(ev)) != sizeof(ev))
			return -1;
		count++;
		if (count >= 256)
			return -1;
	}
	return count;
}

/* ------------------------------------------------------------------ sensores */

static uint8_t *frame_alloc(size_t n)
{
	uint8_t *p = calloc(1, n);

	if (!p)
		DIE("sem memória");
	return p;
}

/* módulo 12, cmd 1 */
static int cmd_build_info(void)
{
	uint8_t *b = frame_alloc(0x418);
	int64_t r = 0;
	size_t len;

	*(uint32_t *)(b + 0x14) = 1024;
	if (ta_send(12, 1, b, 0x418, &r) || r) {
		fprintf(stderr, "get_build_info falhou%s%s\n",
			ta_strerror(r) ? ": " : "", ta_strerror(r) ?: "");
		free(b);
		return -1;
	}
	len = *(uint32_t *)(b + 0x14);
	if (len > 1024) {
		fprintf(stderr, "build-info: tamanho inválido %zu\n", len);
		free(b);
		return -1;
	}
	if (getenv("FPC_TAC_DUMP"))
		hexdump("frame após build-info", b, 0x40);
	printf("build (len %zu, +8=%u +0xc=%u +0x10=%u): %.*s\n", len,
	       *(uint32_t *)(b + 8), *(uint32_t *)(b + 0xc),
	       *(uint32_t *)(b + 0x10), (int)(len ? len - 1 : 0),
	       (char *)(b + 0x18));
	free(b);
	return 0;
}

/* módulo 10, cmd 7: info do OTP */
static void cmd_otp(void)
{
	uint8_t *b = frame_alloc(0x70);
	int64_t r;

	if (ta_send(10, 7, b, 0x70, &r)) {
		free(b);
		return;
	}
	printf("OTP: ta_result=%lld%s%s\n", (long long)r,
	       ta_strerror(r) ? " " : "", ta_strerror(r) ?: "");
	hexdump("OTP payload (frame+8)", b + 8, 0x68);
	free(b);
}

/* Report only whether a challenge was generated; never print the nonce. */
static int cmd_challenge_check(void)
{
	uint8_t *b = frame_alloc(0x70);
	int64_t r = 0;
	uint64_t challenge = 0;
	int ret = ta_send(3, 2, b, 0x70, &r);

	if (!ret && !r) {
		memcpy(&challenge, b + 8, sizeof(challenge));
		printf("desafio FPC: %s (valor omitido)\n", challenge ? "não zero" : "zero");
		if (!challenge)
			ret = -1;
	} else {
		fprintf(stderr, "geração de desafio falhou\n");
		ret = -1;
	}
	explicit_bzero(b, 0x70);
	free(b);
	return ret;
}

/* módulo 10: init/power */
/* cmd 0 = device open/init (provado empiricamente; sem ele os demais cmds
 * do módulo 10 estouram o TA). */
static int sensor_init(void)
{
	uint8_t *b = frame_alloc(0x418);
	int64_t r = 0;
	int ret = 0;

	if (ta_send(10, 0, b, 0x418, &r) || r) {
		fprintf(stderr, "sensor init (cmd 0): %s\n",
			ta_strerror(r) ?: strerror(errno));
		ret = -1;
	} else {
		printf("sensor init ok (id em +0x10: %08x %08x %08x %08x)\n",
		       *(uint32_t *)(b + 0x10), *(uint32_t *)(b + 0x14),
		       *(uint32_t *)(b + 0x18), *(uint32_t *)(b + 0x1c));
	}
	free(b);
	return ret;
}

/*
 * Um ciclo de captura. O TA captura para o buffer interno dele e devolve só o
 * status em frame+0x10 (não há caminho de imagem crua neste firmware).
 */
static int capture_once(int wait_finger, int timeout_ms, uint32_t *status_out)
{
	uint8_t *b = frame_alloc(0x418);
	int64_t r;
	int ret = 0;
	int attempts = 0;
	uint32_t st = 0;

	*(uint8_t *)(b + 8) = wait_finger ? 1 : 0;
	*(uint32_t *)(b + 0xc) = 0;
	*(uint32_t *)(b + 0x14) = 0x20;	/* limite de resposta usado pelo laço */

	for (uint32_t cmd = 1; wait_finger && cmd <= 3; cmd++) {
		if (ta_send(10, cmd, b, 0x418, &r) || r) {
			fprintf(stderr, "capture step (cmd %u) falhou ou retornou valor não interpretado\n", cmd);
			ret = -1;
			goto out;
		}
		printf("sensor cmd %u: retorno TA=%d\n", cmd, g_last_status);
	}

wait_for_finger:
	if (wait_finger) {
		int discarded = g_irq_fd < 0 ? -1 : gpio_discard_pending(g_irq_fd);
		if (discarded < 0) {
			fprintf(stderr, "não foi possível limpar eventos de IRQ\n");
			ret = -1;
			goto out;
		}
		printf("eventos pendentes descartados: %d\n", discarded);
		printf("aponte o dedo no sensor...\n");
		fflush(stdout);
		if (g_irq_fd < 0 || gpio_wait_edge(g_irq_fd, timeout_ms) <= 0) {
			fprintf(stderr, "IRQ não observada; captura cancelada\n");
			ret = -1;
			goto out;
		}
		printf("IRQ observada (relação com toque precisa de confirmação)\n");
	}

	if (ta_send(10, 4, b, 0x418, &r) || r) {
		fprintf(stderr, "capture (cmd 4): %s\n",
			ta_strerror(r) ?: strerror(errno));
		ret = -1;
		goto out;
	}
	st = *(uint32_t *)(b + 0x10);
	printf("capture cmd 4: retorno TA=%d frame+0x10=%u\n", g_last_status, st);
	if (g_last_status == 1 && wait_finger && ++attempts < 4) {
		printf("captura pediu nova tentativa (%d/4); retire e toque novamente\n", attempts);
		if (ta_send(10, 3, b, 0x418, &r) || r) {
			fprintf(stderr, "falha ao rearmar espera\n");
			ret = -1;
			goto out;
		}
		goto wait_for_finger;
	}
	if (g_last_status != 0) {
		fprintf(stderr, "captura não confirmada: retorno TA=%d\n", g_last_status);
		ret = -1;
	}

	if (ta_send(10, 5, b, 0x418, &r) || r)
		fprintf(stderr, "capture_finish (cmd 5): %s\n",
			ta_strerror(r) ?: strerror(errno));
	else
		printf("capture status (frame+0x10) = %u\n", st);

out:
	if (status_out)
		*status_out = st;
	free(b);
	return ret;
}

/* módulo 11 */
static int bio_cmd(uint32_t cmd, uint32_t arg_in, uint32_t *arg_out,
		   int64_t *ta_result)
{
	uint8_t *b = frame_alloc(0x70);
	int64_t r = 0;
	int ret;

	*(uint32_t *)(b + 8) = arg_in;
	ret = ta_send(11, cmd, b, 0x70, &r);
	if (!ret)
		printf("bio cmd %u: status=0x%08x frame+8=%u\n", cmd,
		       (uint32_t)g_last_status, *(uint32_t *)(b + 8));
	if (!ret && arg_out)
		*arg_out = *(uint32_t *)(b + 8);
	if (ta_result)
		*ta_result = r;
	free(b);
	return ret;
}

#include "gk-client.h"

/*
 * @authorize: pede o token ao Gatekeeper e autoriza no TA antes do
 * begin_enrol (sem isso o end_enrol devolve 0xe913406f).
 */
static int do_enroll(int authorize)
{
	uint32_t remaining = 1, id = 0;
	int64_t r = 0;
	int sample = 0;

	if (sensor_init())
		return -1;
	if (!getenv("FPC_RESUME_ENROLL") && (bio_cmd(0, 0, NULL, &r) || r)) {
		fprintf(stderr, "bio_init falhou\n");
		return -1;
	}
	if (authorize && fpc_authorize_enrol())
		return -1;
	if (!getenv("FPC_RESUME_ENROLL") && (bio_cmd(1, 0, NULL, &r) || r)) {
		fprintf(stderr, "begin_enrol falhou\n");
		return -1;
	}

	while (remaining && sample < 20) {
		uint32_t st;

		printf("amostra %d\n", ++sample);
		if (capture_once(1, 120000, &st))
			return -1;
		if (bio_cmd(2, 0, &remaining, &r) || r) {
			fprintf(stderr, "enrol falhou\n");
			return -1;
		}
		printf("  restam %u amostras\n", remaining);
		if (g_last_status == 8)
			printf("  retorno 8: amostra com feedback; significado específico ainda desconhecido\n");
		if (remaining) {
			printf("  retire o dedo e reposicione antes da próxima amostra\n");
			fflush(stdout);
			sleep(3);
		}
		fflush(stdout);
	}
	if (remaining) {
		fprintf(stderr, "cadastro incompleto: restam %u amostras\n", remaining);
		return -1;
	}

	if (bio_cmd(3, 0, &id, &r) || r) {
		fprintf(stderr, "end_enrol falhou\n");
		return -1;
	}
	printf("cadastrado, id %u\n", id);
	return 0;
}

static int do_identify(int timeout_ms)
{
	uint8_t *b = frame_alloc(0x70);
	uint32_t st, id;
	int64_t r;
	int ret = 0;

	if (capture_once(1, timeout_ms, &st))
		return -1;

	if (ta_send(11, 4, b, 0x70, &r) || r) {
		fprintf(stderr, "identify: %s\n", ta_strerror(r) ?: "ok");
		ret = -1;
		goto out;
	}
	id = *(uint32_t *)(b + 8);
	if (!id) {
		printf("não reconhecido (nenhum template casou)\n");
	} else {
		printf("reconhecido: id %u, coverage %u, quality %u\n", id,
		       *(uint32_t *)(b + 0xc), *(uint32_t *)(b + 0x10));
	}
out:
	free(b);
	return ret;
}

/* módulo 4: blob de templates */
#define BLOB_CHUNK (1u << 20)

static int blob_open(uint32_t mode, uint32_t size)
{
	uint8_t *b = frame_alloc(0x70);
	int64_t r;
	int ret;

	*(uint32_t *)(b + 0xc) = mode;
	*(uint32_t *)(b + 0x10) = size;
	ret = ta_send(4, 14, b, 0x70, &r);
	if (!ret && r)
		fprintf(stderr, "blob open: %s\n", ta_strerror(r) ?: "ok");
	free(b);
	return ret || r ? -1 : 0;
}

static uint32_t blob_size(void)
{
	uint8_t *b = frame_alloc(0x70);
	int64_t r;
	uint32_t size = 0;

	if (!ta_send(4, 6, b, 0x70, &r) && !r)
		size = *(uint32_t *)(b + 8);
	else
		fprintf(stderr, "blob size: %s\n", ta_strerror(r) ?: "ok");
	free(b);
	return size;
}

static void blob_reset(void)
{
	uint8_t *b = frame_alloc(0x70);
	int64_t r;

	ta_send(4, 15, b, 0x70, &r);
	free(b);
}

static int do_db_store(const char *path)
{
	uint32_t size = blob_size(), got = 0;
	uint8_t *chunk;
	int64_t r;
	FILE *f;

	if (!size) {
		fprintf(stderr, "banco vazio no TA\n");
		return -1;
	}
	printf("banco: %u bytes empacotados\n", size);
	if (blob_open(0, size))
		return -1;

	f = fopen(path, "wb");
	if (!f) {
		fprintf(stderr, "%s: %s\n", path, strerror(errno));
		blob_reset();
		return -1;
	}
	chunk = frame_alloc((size < BLOB_CHUNK ? size : BLOB_CHUNK) + 0x10);

	while (got < size) {
		uint32_t want = size - got;

		if (want > BLOB_CHUNK)
			want = BLOB_CHUNK;
		*(uint32_t *)(chunk + 8) = want;
		if (ta_send(4, 16, chunk, want + 0xc, &r) || r < 0) {
			fprintf(stderr, "blob read: %s\n", ta_strerror(r) ?: "ok");
			goto err;
		}
		fwrite(chunk + 0xc, 1, want, f);
		got += want;
		printf("  %u/%u\n", got, size);
		if (r == 0)
			break;
	}
	fclose(f);
	blob_reset();
	free(chunk);
	printf("gravado em %s\n", path);
	return 0;
err:
	fclose(f);
	blob_reset();
	free(chunk);
	return -1;
}

static int do_db_load(const char *path)
{
	struct stat st;
	uint8_t *chunk;
	uint32_t off = 0;
	int64_t r;
	int fd = open(path, O_RDONLY);

	if (fd < 0) {
		fprintf(stderr, "%s: %s (o TA deve começar com banco vazio)\n", path,
			strerror(errno));
		return -1;
	}
	if (fstat(fd, &st)) {
		close(fd);
		return -1;
	}
	printf("enviando %zu bytes de %s\n", st.st_size, path);
	if (blob_open(1, st.st_size)) {
		close(fd);
		return -1;
	}
	chunk = frame_alloc((st.st_size < BLOB_CHUNK ? st.st_size : BLOB_CHUNK) + 0x10);

	while (off < st.st_size) {
		uint32_t want = st.st_size - off;

		if (want > BLOB_CHUNK)
			want = BLOB_CHUNK;
		if (read(fd, chunk + 0xc, want) != (ssize_t)want) {
			fprintf(stderr, "leitura curta\n");
			goto err;
		}
		*(uint32_t *)(chunk + 8) = want;
		if (ta_send(4, 17, chunk, want + 0xc, &r) || r < 0) {
			fprintf(stderr, "blob write: %s\n", ta_strerror(r) ?: "ok");
			goto err;
		}
		off += want;
		printf("  %u/%zu\n", off, st.st_size);
	}
	close(fd);
	blob_reset();
	free(chunk);
	printf("banco carregado no TA\n");
	return 0;
err:
	close(fd);
	blob_reset();
	free(chunk);
	return -1;
}

/* módulo 5: self test de fabrica */
static int do_selftest(void)
{
	uint8_t *b = frame_alloc(0x34);
	int64_t r;
	int ret = 0;

	for (uint32_t cmd = 0; cmd <= 2; cmd++) {
		if (ta_send(5, cmd, b, 0x34, &r) || r) {
			fprintf(stderr, "selftest cmd %u: %s\n", cmd,
				ta_strerror(r) ?: "ok");
			ret = -1;
			break;
		}
		printf("selftest cmd %u ok (status %u)\n", cmd,
		       *(uint32_t *)(b + 0x2c));
	}
	free(b);
	return ret;
}

/* -------------------------------------------------------------------- main */

static void usage(void)
{
	fprintf(stderr,
		"uso: fpc-tac [opções] comando\n"
		"  --fw DIR       diretório do TA (default /mnt/ro/modem_a/image)\n"
		"  --dev NODE     default /dev/qseecom-fpc\n"
		"  --gpiochip N   default /dev/gpiochip0\n"
		"  --enable N     GPIO de alimentação (default 29, 0 = não tocar)\n"
		"  --reset N      GPIO de reset (default 4)\n"
		"  --irq N        GPIO de IRQ (default 90)\n"
		"  --app-id N     usa um TA já carregado (0 = o que o driver carregou)\n"
		"comandos: info build-info otp power-on power-off sensor-init\n"
		"          capture [--no-wait] identify enroll db-store ARQ db-load ARQ\n"
		"          selftest auth-test enroll-auth [ARQ]\n");
	exit(1);
}

int main(int argc, char **argv)
{
	const char *fw = "/mnt/ro/modem_a/image", *dev = "/dev/qseecom-fpc";
	const char *chip = "/dev/gpiochip0";
	int enable = 29, reset = 4, irq = 90;
	int gpio_out = -1;
	int no_wait = 0;
	const char *cmd = NULL, *file = NULL;
	struct qseecom_fpc_info info;
	int i;

	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--fw") && i + 1 < argc)
			fw = argv[++i];
		else if (!strcmp(argv[i], "--dev") && i + 1 < argc)
			dev = argv[++i];
		else if (!strcmp(argv[i], "--gpiochip") && i + 1 < argc)
			chip = argv[++i];
		else if (!strcmp(argv[i], "--enable") && i + 1 < argc)
			enable = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--reset") && i + 1 < argc)
			reset = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--irq") && i + 1 < argc)
			irq = atoi(argv[++i]);
		else if (!strcmp(argv[i], "--app-id") && i + 1 < argc)
			g_app_id = (uint32_t)strtoul(argv[++i], NULL, 0);
		else if (!strcmp(argv[i], "--no-wait"))
			no_wait = 1;
		else if (argv[i][0] == '-')
			usage();
		else if (!cmd)
			cmd = argv[i];
		else
			file = argv[i];
	}
	if (!cmd)
		usage();

	tac.fd = open(dev, O_RDWR);
	if (tac.fd < 0)
		DIE("%s: %s (módulo qcom_qseecom_fpc carregado?)", dev,
		    strerror(errno));
	tac.frame_len = QSEECOM_FPC_MAX_FRAME;
	tac.frame = frame_alloc(tac.frame_len);

	if (ioctl(tac.fd, QSEECOM_FPC_INFO, &info) == 0 && info.app_loaded) {
		tac.app_loaded = 1;
		printf("TA já carregado (app_id %u)\n", info.app_id);
	}
	if (!strcmp(cmd, "unload")) {
		if (ioctl(tac.fd, QSEECOM_FPC_UNLOAD_APP) < 0)
			DIE("UNLOAD_APP: %s", strerror(errno));
		printf("pedido de encerramento enviado (driver não confirma resultado do TEE)\n");
		close(tac.fd);
		return 0;
	}

	/* energia + reset antes de qualquer comando que fale com o sensor */
	if (enable > 0) {
		gpio_out = gpio_out_request(chip, enable, reset);
		/* enable já em 1; pulso de reset: baixo -> alto */
		gpio_out_set(gpio_out, 0x2, 0x0);
		usleep(4000);
		gpio_out_set(gpio_out, 0x2, 0x2);
		usleep(12000);
	}

	if (!tac.app_loaded && !g_app_id)
		load_app(fw);

	if (irq > 0)
		g_irq_fd = gpio_edge_request(chip, irq);

	if (!strcmp(cmd, "info")) {
		if (ioctl(tac.fd, QSEECOM_FPC_INFO, &info) == 0)
			printf("app_id=%u carregado=%u frame=%u\n", info.app_id,
			       info.app_loaded, info.frame_len);
	} else if (!strcmp(cmd, "build-info")) {
		return cmd_build_info() ? 1 : 0;
	} else if (!strcmp(cmd, "otp")) {
		cmd_otp();
	} else if (!strcmp(cmd, "challenge-check")) {
		return cmd_challenge_check() ? 1 : 0;
	} else if (!strcmp(cmd, "sensor-init")) {
		return sensor_init() ? 1 : 0;
	} else if (!strcmp(cmd, "capture")) {
		uint32_t st = 0;
		int ret = sensor_init();

		if (!ret)
			ret = capture_once(!no_wait, 120000, &st);

		printf("capture: status %u%s%s\n", st,
		       ret ? " (falhou)" : "", "");
		return ret ? 1 : 0;
	} else if (!strcmp(cmd, "identify")) {
		return do_identify(5000) ? 1 : 0;
	} else if (!strcmp(cmd, "identify-db")) {
		/*
		 * TA recém-carregado: sensor init e bio init ANTES de tudo (sem
		 * eles o TA estoura e o TEE mata o app), depois o banco do
		 * arquivo, depois uma identificação.
		 */
		int64_t r = 0;

		if (!file)
			DIE("identify-db precisa do arquivo do banco");
		if (sensor_init() || bio_cmd(0, 0, NULL, &r) || r)
			return 1;
		if (do_db_load(file))
			return 1;
		return do_identify(60000) ? 1 : 0;
	} else if (!strcmp(cmd, "enroll")) {
		return do_enroll(0) ? 1 : 0;
	} else if (!strcmp(cmd, "auth-test")) {
		/* tudo menos as capturas: hw_auth, desafio, token, authorize */
		int64_t r = 0;

		if (sensor_init() || bio_cmd(0, 0, NULL, &r) || r)
			return 1;
		return fpc_authorize_enrol() ? 1 : 0;
	} else if (!strcmp(cmd, "db-list") || !strcmp(cmd, "db-delete")) {
		/* db-list ARQ | db-delete ARQ: inits + banco; delete lê o id de FPC_ID */
		uint8_t *b = frame_alloc(0x70);
		int64_t r = 0;
		uint32_t n;

		if (!file)
			DIE("%s precisa do arquivo do banco", cmd);
		if (sensor_init() || bio_cmd(0, 0, NULL, &r) || r || do_db_load(file))
			return 1;
		if (!strcmp(cmd, "db-delete")) {
			uint32_t id = (uint32_t)strtoul(getenv("FPC_ID") ?: "0", NULL, 0);

			if (!id)
				DIE("defina FPC_ID");
			*(uint32_t *)(b + 8) = id;
			if (ta_send(11, 9, b, 0x70, &r) || r)
				DIE("delete_template %u falhou", id);
			printf("template %u apagado\n", id);
			if (do_db_store(file))
				return 1;
			memset(b, 0, 0x70);
		}
		*(uint32_t *)(b + 8) = 16;
		if (ta_send(11, 8, b, 0x70, &r) || r)
			DIE("get_finger_ids falhou");
		n = *(uint32_t *)(b + 8);
		printf("%u template(s):", n);
		for (uint32_t i = 0; i < n && i < 16; i++)
			printf(" %u", *(uint32_t *)(b + 0xc + 4 * i));
		printf("\n");
		free(b);
		return 0;
	} else if (!strcmp(cmd, "begin-test")) {
		/* sem toque: inits, [banco], token, begin_enrol; mostra o status */
		int64_t r = 0;

		if (sensor_init() || bio_cmd(0, 0, NULL, &r) || r)
			return 1;
		if (file && do_db_load(file))
			return 1;
		if (fpc_authorize_enrol())
			return 1;
		bio_cmd(1, 0, NULL, &r);
		printf("begin_enrol: status 0x%08x\n", (uint32_t)g_last_status);
		return g_last_status ? 1 : 0;
	} else if (!strcmp(cmd, "enroll-auth")) {
		const char *db = file ? file : GK_DIR "/templates.bin";

		if (do_enroll(1))
			return 1;
		return do_db_store(db) ? 1 : 0;
	} else if (!strcmp(cmd, "db-store")) {
		if (!file)
			DIE("db-store precisa de um caminho");
		return do_db_store(file) ? 1 : 0;
	} else if (!strcmp(cmd, "db-load")) {
		if (!file)
			DIE("db-load precisa de um caminho");
		return do_db_load(file) ? 1 : 0;
	} else if (!strcmp(cmd, "raw")) {
		/* raw MODULE CMD [LEN]: envia um frame cru e mostra tudo */
		unsigned mod = argc > 2 ? (unsigned)strtoul(argv[argc - 3], NULL, 0) : 0;
		unsigned c = argc > 2 ? (unsigned)strtoul(argv[argc - 2], NULL, 0) : 0;
		size_t len = argc > 3 ? strtoul(argv[argc - 1], NULL, 0) :
					QSEECOM_FPC_MAX_FRAME;

		if (len < 8 || len > QSEECOM_FPC_MAX_FRAME)
			len = QSEECOM_FPC_MAX_FRAME;
		uint8_t *fb = frame_alloc(len);
		int64_t r = 0;
		int ret;

		*(uint32_t *)(fb + 0x14) = 0x400;
		/* módulos 3/4/5/11 usam +8 como tamanho do payload em +0xc */
		*(uint32_t *)(fb + 0x8) = (uint32_t)(len > 0xc ? len - 0xc : 0);
		ret = ta_send(mod, c, fb, len, &r);
		printf("raw m%u c%u: ret=%d ta_result=%lld status=0x%08x\n", mod, c,
		       ret, (long long)r, (unsigned)g_last_status);
		hexdump("frame", fb, 0x60);
		/* despeja o frame inteiro para inspeção offline */
		{
			int dfd = open("/tmp/fpc-frame.bin",
				       O_WRONLY | O_CREAT | O_TRUNC, 0600);

			if (dfd >= 0) {
				ssize_t w = write(dfd, fb, len);

				close(dfd);
				printf("frame despejado em /tmp/fpc-frame.bin (%zd bytes)\n", w);
			}
		}
		free(fb);
	} else if (!strcmp(cmd, "selftest")) {
		return do_selftest() ? 1 : 0;
	} else if (!strcmp(cmd, "power-on")) {
		gpio_out_set(gpio_out, 0x1, 0x1);
	} else if (!strcmp(cmd, "power-off")) {
		gpio_out_set(gpio_out, 0x1, 0x0);
	} else {
		usage();
	}

	if (gpio_out >= 0)
		close(gpio_out);
	close(tac.fd);
	return 0;
}
