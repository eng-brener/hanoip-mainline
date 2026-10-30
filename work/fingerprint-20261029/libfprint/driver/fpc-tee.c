// SPDX-License-Identifier: LGPL-2.1-or-later
/*
 * Núcleo do leitor FPC do Moto G60 (hanoip). Ver fpc-tee.h.
 *
 * Portado do cliente de diagnóstico fpc-tac (userspace/fpc-tac.c e
 * gk-client.h), sem saídas no terminal nem exit(): cada função devolve um
 * código e deixa a explicação em t->err.
 */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <errno.h>
#include <fcntl.h>
#include <linux/gpio.h>
#include <poll.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>

#include "qseecom-fpc.h"
#include "fpc-tee.h"

#define GPIO_ENABLE		29
#define GPIO_RESET		4
#define GPIO_IRQ		90
#define GPIO_CHIP_LABEL		"3500000.pinctrl"	/* TLMM */

#define GK_NEW_ENROLL		0x21001
#define GK_NEW_VERIFY		0x21002
#define KM_GET_AUTH_TOKEN_KEY	0x205
#define GK_UID			0x4b414c49u	/* "KALI": não é usuário Android */
#define GK_HANDLE_LEN		58
#define GK_SECRET_LEN		32
#define GK_HAT_LEN		69
#define GK_DIR			"/var/lib/fpc-gk"
#define GK_RSP_LEN		0x8000

__attribute__((format(printf, 3, 4)))
static int fail(struct fpc_tee *t, int ret, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vsnprintf(t->err, sizeof(t->err), fmt, ap);
	va_end(ap);
	return ret;
}

/* ------------------------------------------------------------ transporte */

/*
 * Um comando ao fpctzapp. O status do TA (rsp[0]) fica em t->last_status;
 * quem chama decide o que é sucesso (alguns comandos devolvem estados > 0).
 */
static int ta_call(struct fpc_tee *t, uint32_t module, uint32_t cmd,
		   uint8_t *buf, size_t len)
{
	uint8_t req[QSEECOM_FPC_CTRL_LEN], rsp[QSEECOM_FPC_RSP_LEN];
	struct qseecom_fpc_send arg = {
		.req = (uintptr_t)req,
		.rsp = (uintptr_t)rsp,
		.frame = (uintptr_t)buf,
		.frame_len = (uint32_t)len,
		.status = (int32_t)0xaaaaaaaa,
	};

	memcpy(buf, &module, 4);
	memcpy(buf + 4, &cmd, 4);
	if (ioctl(t->fd, QSEECOM_FPC_SEND, &arg) < 0)
		return fail(t, -errno, "TA m%u c%u: %s", module, cmd,
			    strerror(errno));
	if ((uint32_t)arg.status == 0xaaaaaaaau)
		return fail(t, -EIO, "driver sem status do TA");
	t->last_status = arg.status;
	return 0;
}

/* ta_call que só aceita status 0 */
static int ta_ok(struct fpc_tee *t, uint32_t module, uint32_t cmd,
		 uint8_t *buf, size_t len)
{
	int ret = ta_call(t, module, cmd, buf, len);

	if (ret)
		return ret;
	if (t->last_status)
		return fail(t, FPC_TEE_ERR_TA, "TA m%u c%u: status 0x%08x",
			    module, cmd, (uint32_t)t->last_status);
	return 0;
}

static int km_send(struct fpc_tee *t, const void *req, size_t req_len,
		   uint8_t *rsp)
{
	struct qseecom_fpc_send_raw arg = {
		.req = (uintptr_t)req,
		.req_len = (uint32_t)req_len,
		.rsp = (uintptr_t)rsp,
		.rsp_len = GK_RSP_LEN,
	};

	if (!t->km_app_id) {
		struct qseecom_fpc_app_id id = { .name = "keymaster64" };

		if (ioctl(t->fd, QSEECOM_FPC_GET_APP_ID, &id))
			return fail(t, -errno, "keymaster64: %s",
				    strerror(errno));
		t->km_app_id = id.app_id;
	}
	arg.app_id = t->km_app_id;
	memset(rsp, 0, GK_RSP_LEN);
	if (ioctl(t->fd, QSEECOM_FPC_SEND_RAW, &arg))
		return fail(t, -errno, "keymaster: %s", strerror(errno));
	return 0;
}

/* ------------------------------------------------------------ GPIO */

static int gpio_find_chip(struct fpc_tee *t)
{
	char path[32];
	int i, fd;

	for (i = 0; i < 16; i++) {
		struct gpiochip_info info = { 0 };

		snprintf(path, sizeof(path), "/dev/gpiochip%d", i);
		fd = open(path, O_RDWR | O_CLOEXEC);
		if (fd < 0)
			continue;
		if (!ioctl(fd, GPIO_GET_CHIPINFO_IOCTL, &info) &&
		    !strcmp(info.label, GPIO_CHIP_LABEL))
			return fd;
		close(fd);
	}
	return fail(t, -ENODEV, "gpiochip %s não encontrado", GPIO_CHIP_LABEL);
}

static int gpio_set(int fd, uint64_t mask, uint64_t bits)
{
	struct gpio_v2_line_values v = { .bits = bits, .mask = mask };

	return ioctl(fd, GPIO_V2_LINE_SET_VALUES_IOCTL, &v);
}

static int gpio_setup(struct fpc_tee *t)
{
	struct gpio_v2_line_request out = { 0 }, irq = { 0 };
	int chip = gpio_find_chip(t);

	if (chip < 0)
		return chip;

	out.num_lines = 2;
	out.offsets[0] = GPIO_ENABLE;
	out.offsets[1] = GPIO_RESET;
	snprintf(out.consumer, sizeof(out.consumer), "hanoip-fpc");
	out.config.flags = GPIO_V2_LINE_FLAG_OUTPUT;
	out.config.num_attrs = 1;
	out.config.attrs[0].attr.id = GPIO_V2_LINE_ATTR_ID_OUTPUT_VALUES;
	out.config.attrs[0].attr.values = 0;
	out.config.attrs[0].mask = 0x3;
	if (ioctl(chip, GPIO_V2_GET_LINE_IOCTL, &out) < 0) {
		close(chip);
		return fail(t, -errno, "gpio %u/%u: %s", GPIO_ENABLE,
			    GPIO_RESET, strerror(errno));
	}
	t->gpio_out = out.fd;

	irq.num_lines = 1;
	irq.event_buffer_size = 16;
	irq.offsets[0] = GPIO_IRQ;
	snprintf(irq.consumer, sizeof(irq.consumer), "hanoip-fpc");
	/* O driver Android usa IRQF_TRIGGER_RISING (fpc1020_tee.c). */
	irq.config.flags = GPIO_V2_LINE_FLAG_INPUT |
			   GPIO_V2_LINE_FLAG_EDGE_RISING |
			   GPIO_V2_LINE_FLAG_BIAS_PULL_DOWN;
	if (ioctl(chip, GPIO_V2_GET_LINE_IOCTL, &irq) < 0) {
		close(chip);
		return fail(t, -errno, "gpio irq %u: %s", GPIO_IRQ,
			    strerror(errno));
	}
	t->irq_fd = irq.fd;
	close(chip);

	/* energia ligada, pulso de reset: baixo -> alto */
	gpio_set(t->gpio_out, 0x3, 0x1);
	usleep(4000);
	gpio_set(t->gpio_out, 0x2, 0x2);
	usleep(12000);
	return 0;
}

/* Descarta bordas antigas: não são um toque novo. */
static int gpio_discard(struct fpc_tee *t)
{
	struct gpio_v2_line_event ev;
	struct pollfd pfd = { .fd = t->irq_fd, .events = POLLIN };
	int n = 0;

	while (poll(&pfd, 1, 0) > 0 && (pfd.revents & POLLIN)) {
		if (read(t->irq_fd, &ev, sizeof(ev)) != sizeof(ev) || ++n > 256)
			return fail(t, -EIO, "fila de IRQ inválida");
	}
	return 0;
}

static int gpio_wait(struct fpc_tee *t, int cancel_fd)
{
	struct gpio_v2_line_event ev;
	struct pollfd pfd[2] = {
		{ .fd = t->irq_fd, .events = POLLIN },
		{ .fd = cancel_fd, .events = POLLIN },
	};

	for (;;) {
		int n = poll(pfd, cancel_fd >= 0 ? 2 : 1, -1);

		if (n < 0 && errno == EINTR)
			continue;
		if (n < 0)
			return fail(t, -errno, "poll: %s", strerror(errno));
		if (cancel_fd >= 0 && (pfd[1].revents & POLLIN))
			return fail(t, -ECANCELED, "cancelado");
		if (pfd[0].revents & POLLIN) {
			if (read(t->irq_fd, &ev, sizeof(ev)) != sizeof(ev))
				return fail(t, -EIO, "leitura da IRQ");
			return 0;
		}
	}
}

/* ------------------------------------------------------------ TA */

static int read_file(const char *path, uint8_t **out, size_t *len)
{
	struct stat st;
	uint8_t *p;
	int fd = open(path, O_RDONLY | O_CLOEXEC);

	if (fd < 0)
		return -errno;
	if (fstat(fd, &st) || st.st_size <= 0) {
		close(fd);
		return -EIO;
	}
	p = malloc(st.st_size);
	if (!p || read(fd, p, st.st_size) != st.st_size) {
		free(p);
		close(fd);
		return -EIO;
	}
	close(fd);
	*out = p;
	*len = st.st_size;
	return 0;
}

/* Imagem para o TEE: [.mdt][b00][b01]..., mdt_len = tamanho do .mdt. */
static int load_app(struct fpc_tee *t, const char *fwdir)
{
	struct qseecom_fpc_load arg = { 0 };
	char path[256];
	uint8_t *img, *seg, *grown;
	size_t total, mdt_len, n;
	int i, ret;

	snprintf(path, sizeof(path), "%s/fpctzapp.mdt", fwdir);
	ret = read_file(path, &img, &mdt_len);
	if (ret)
		return fail(t, ret, "não li %s", path);
	total = mdt_len;
	for (i = 0; i < 16; i++) {
		snprintf(path, sizeof(path), "%s/fpctzapp.b%02d", fwdir, i);
		if (read_file(path, &seg, &n))
			break;
		grown = realloc(img, total + n);
		if (!grown) {
			free(seg);
			free(img);
			return fail(t, -ENOMEM, "sem memória");
		}
		img = grown;
		memcpy(img + total, seg, n);
		total += n;
		free(seg);
	}
	if (total == mdt_len) {
		free(img);
		return fail(t, -ENOENT, "sem segmentos fpctzapp.bXX em %s",
			    fwdir);
	}
	arg.image = (uintptr_t)img;
	arg.image_len = (uint32_t)total;
	arg.mdt_len = (uint32_t)mdt_len;
	ret = ioctl(t->fd, QSEECOM_FPC_LOAD_APP, &arg);
	free(img);
	if (ret < 0)
		return fail(t, -errno, "LOAD_APP: %s", strerror(errno));
	return 0;
}

int fpc_tee_open(struct fpc_tee *t, const char *dev, const char *fwdir)
{
	struct qseecom_fpc_info info = { 0 };
	int ret, tries;

	memset(t, 0, sizeof(*t));
	t->gpio_out = t->irq_fd = -1;
	t->fd = open(dev, O_RDWR | O_CLOEXEC);
	if (t->fd < 0)
		return fail(t, -errno, "%s: %s", dev, strerror(errno));

	ret = gpio_setup(t);
	if (ret)
		goto err;
	/*
	 * Sempre um TA novo: um TA que sobrou de outra sessão já passou por
	 * bio init e carga do banco, e repetir isso falha (0xe892834b). O TEE
	 * às vezes recusa a carga logo depois de um encerramento: tenta de
	 * novo após 1 s.
	 */
	if (!ioctl(t->fd, QSEECOM_FPC_INFO, &info) && info.app_loaded)
		ioctl(t->fd, QSEECOM_FPC_UNLOAD_APP);
	for (tries = 0; tries < 3; tries++) {
		if (tries)
			sleep(1);
		ret = load_app(t, fwdir);
		if (ret != -EINVAL)
			break;
	}
	if (ret)
		goto err;
	return 0;
err:
	fpc_tee_close(t);
	return ret;
}

void fpc_tee_close(struct fpc_tee *t)
{
	/* o TA não sobrevive à sessão: a próxima abertura começa do zero */
	if (t->fd >= 0)
		ioctl(t->fd, QSEECOM_FPC_UNLOAD_APP);
	if (t->irq_fd >= 0)
		close(t->irq_fd);
	if (t->gpio_out >= 0)
		close(t->gpio_out);
	if (t->fd >= 0)
		close(t->fd);
	t->fd = t->gpio_out = t->irq_fd = -1;
}

/* ------------------------------------------------------------ banco */

#define BLOB_CHUNK	(1u << 20)

static void blob_reset(struct fpc_tee *t)
{
	uint8_t b[0x70] = { 0 };

	ta_call(t, 4, 15, b, sizeof(b));
}

static int blob_open(struct fpc_tee *t, uint32_t mode, uint32_t size)
{
	uint8_t b[0x70] = { 0 };

	memcpy(b + 0xc, &mode, 4);
	memcpy(b + 0x10, &size, 4);
	return ta_ok(t, 4, 14, b, sizeof(b));
}

static int db_load(struct fpc_tee *t, const char *path)
{
	uint8_t *data, *chunk;
	size_t len, off = 0;
	int ret;

	ret = read_file(path, &data, &len);
	if (ret == -ENOENT)
		return 0;	/* sem banco ainda: começa vazio */
	if (ret)
		return fail(t, ret, "não li %s", path);
	ret = blob_open(t, 1, (uint32_t)len);
	if (ret)
		goto out;
	chunk = malloc((len < BLOB_CHUNK ? len : BLOB_CHUNK) + 0x10);
	if (!chunk) {
		ret = fail(t, -ENOMEM, "sem memória");
		goto reset;
	}
	while (off < len) {
		uint32_t want = len - off > BLOB_CHUNK ? BLOB_CHUNK : len - off;

		memset(chunk, 0, 0xc);
		memcpy(chunk + 8, &want, 4);
		memcpy(chunk + 0xc, data + off, want);
		ret = ta_call(t, 4, 17, chunk, want + 0xc);
		if (!ret && t->last_status < 0)
			ret = fail(t, FPC_TEE_ERR_TA, "blob write: 0x%08x",
				   (uint32_t)t->last_status);
		if (ret)
			break;
		off += want;
	}
	free(chunk);
reset:
	blob_reset(t);
out:
	free(data);
	return ret;
}

int fpc_tee_db_store(struct fpc_tee *t, const char *path)
{
	uint8_t b[0x70] = { 0 }, *chunk;
	uint32_t size, got = 0;
	char tmp[256];
	int fd, ret;

	ret = ta_ok(t, 4, 6, b, sizeof(b));
	if (ret)
		return ret;
	memcpy(&size, b + 8, 4);
	if (!size)
		return fail(t, -ENODATA, "banco vazio no TA");
	ret = blob_open(t, 0, size);
	if (ret)
		return ret;

	snprintf(tmp, sizeof(tmp), "%s.new", path);
	fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
	chunk = malloc((size < BLOB_CHUNK ? size : BLOB_CHUNK) + 0x10);
	if (fd < 0 || !chunk) {
		ret = fail(t, -EIO, "não abri %s", tmp);
		goto out;
	}
	while (got < size) {
		uint32_t want = size - got > BLOB_CHUNK ? BLOB_CHUNK : size - got;

		memset(chunk, 0, 0xc);
		memcpy(chunk + 8, &want, 4);
		ret = ta_call(t, 4, 16, chunk, want + 0xc);
		if (!ret && t->last_status < 0)
			ret = fail(t, FPC_TEE_ERR_TA, "blob read: 0x%08x",
				   (uint32_t)t->last_status);
		if (ret)
			goto out;
		if (write(fd, chunk + 0xc, want) != (ssize_t)want) {
			ret = fail(t, -EIO, "escrita em %s", tmp);
			goto out;
		}
		got += want;
	}
	if (fsync(fd)) {
		ret = fail(t, -EIO, "fsync %s", tmp);
		goto out;
	}
	close(fd);
	fd = -1;
	if (rename(tmp, path))
		ret = fail(t, -errno, "rename %s", path);
out:
	if (fd >= 0) {
		close(fd);
		unlink(tmp);
	}
	free(chunk);
	blob_reset(t);
	return ret;
}

/* ------------------------------------------------------------ sensor e bio */

int fpc_tee_start(struct fpc_tee *t, const char *db_path)
{
	uint8_t *b = calloc(1, 0x418);
	int ret;

	if (!b)
		return fail(t, -ENOMEM, "sem memória");
	/*
	 * m10c0 e m11c0 ANTES de qualquer outro comando: sem eles o TA
	 * estoura e o TEE mata o app (todo envio seguinte volta -EINVAL).
	 */
	ret = ta_ok(t, 10, 0, b, 0x418);
	if (!ret) {
		memset(b, 0, 0x70);
		ret = ta_ok(t, 11, 0, b, 0x70);
	}
	free(b);
	if (!ret && db_path)
		ret = db_load(t, db_path);
	return ret;
}

int fpc_tee_capture(struct fpc_tee *t, int cancel_fd)
{
	uint8_t *b = calloc(1, 0x418);
	uint32_t cmd;
	int ret, tries = 0;

	if (!b)
		return fail(t, -ENOMEM, "sem memória");
	b[8] = 1;			/* esperar o dedo */
	b[0x14] = 0x20;

	/* c1 devolve estados 0..3 legítimos; c2/c3 armam a espera */
	for (cmd = 1; cmd <= 3; cmd++) {
		ret = ta_call(t, 10, cmd, b, 0x418);
		if (!ret && t->last_status &&
		    !(cmd == 1 && t->last_status > 0 && t->last_status <= 3))
			ret = fail(t, FPC_TEE_ERR_TA, "sensor c%u: 0x%08x", cmd,
				   (uint32_t)t->last_status);
		if (ret)
			goto out;
	}
	for (;;) {
		ret = gpio_discard(t);
		if (!ret)
			ret = gpio_wait(t, cancel_fd);
		if (ret)
			goto finish;
		ret = ta_call(t, 10, 4, b, 0x418);
		if (ret)
			goto finish;
		if (t->last_status == 1 && ++tries < 4) {
			/* o TA pediu nova tentativa: rearma e espera de novo */
			ret = ta_ok(t, 10, 3, b, 0x418);
			if (ret)
				goto finish;
			continue;
		}
		ret = t->last_status ? FPC_TEE_RETRY : 0;
		break;
	}
finish:
	{
		int32_t keep = t->last_status;

		ta_call(t, 10, 5, b, 0x418);	/* fecha a captura sempre */
		t->last_status = keep;
	}
out:
	free(b);
	return ret;
}

int fpc_tee_enrol_sample(struct fpc_tee *t, uint32_t *remaining)
{
	uint8_t b[0x70] = { 0 };
	int ret = ta_call(t, 11, 2, b, sizeof(b));

	if (ret)
		return ret;
	/* 0 = completo, 6 = faltam amostras, 8 = amostra com aviso */
	if (t->last_status && t->last_status != 6 && t->last_status != 8)
		return fail(t, FPC_TEE_ERR_TA, "enrol: 0x%08x",
			    (uint32_t)t->last_status);
	memcpy(remaining, b + 8, 4);
	if (!t->last_status)
		*remaining = 0;
	return 0;
}

int fpc_tee_enrol_end(struct fpc_tee *t, uint32_t *id)
{
	uint8_t b[0x70] = { 0 };
	int ret = ta_ok(t, 11, 3, b, sizeof(b));

	if (!ret)
		memcpy(id, b + 8, 4);
	return ret;
}

int fpc_tee_list(struct fpc_tee *t, uint32_t *ids, uint32_t *count)
{
	uint8_t b[0x70] = { 0 };
	uint32_t cap = *count, n;
	int ret;

	if (cap > (sizeof(b) - 0xc) / 4)
		cap = (sizeof(b) - 0xc) / 4;
	memcpy(b + 8, &cap, 4);
	ret = ta_ok(t, 11, 8, b, sizeof(b));	/* get_finger_ids */
	if (ret)
		return ret;
	memcpy(&n, b + 8, 4);
	if (n > cap)
		return fail(t, -EIO, "TA listou %u templates (cabem %u)", n, cap);
	memcpy(ids, b + 0xc, n * 4);
	*count = n;
	return 0;
}

int fpc_tee_delete(struct fpc_tee *t, uint32_t id)
{
	uint8_t b[0x70] = { 0 };

	memcpy(b + 8, &id, 4);
	return ta_ok(t, 11, 9, b, sizeof(b));	/* delete_template */
}

int fpc_tee_identify(struct fpc_tee *t, uint32_t *id)
{
	uint8_t b[0x70] = { 0 };
	int ret = ta_ok(t, 11, 4, b, sizeof(b));

	if (!ret)
		memcpy(id, b + 8, 4);
	return ret;
}

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
		return 0;
	n = (size_t)1 << (ai - 24);
	if (len < 1 + n)
		return 0;
	*v = 0;
	for (i = 0; i < n; i++)
		*v = *v << 8 | p[1 + i];
	return 1 + n;
}

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

/* ------------------------------------------------------------ Gatekeeper */

static int gk_call(struct fpc_tee *t, uint32_t cmd, const uint8_t *cbor,
		   size_t cbor_len, uint8_t *rsp, const uint8_t **map,
		   size_t *map_len)
{
	uint8_t req[512];
	int32_t status;
	uint32_t len;
	int ret;

	if (cbor_len + 4 > sizeof(req))
		return fail(t, -EINVAL, "pedido GK grande demais");
	memcpy(req, &cmd, 4);
	memcpy(req + 4, cbor, cbor_len);
	ret = km_send(t, req, cbor_len + 4, rsp);
	explicit_bzero(req, sizeof(req));
	if (ret)
		return ret;
	memcpy(&status, rsp, 4);
	memcpy(&len, rsp + 4, 4);
	if (status)
		return fail(t, -EACCES, "gatekeeper %#x: status %d", cmd,
			    status);
	if (len > GK_RSP_LEN - 8)
		return fail(t, -EIO, "gatekeeper %#x: tamanho %u", cmd, len);
	*map = rsp + 8;
	*map_len = len;
	return 0;
}

static int gk_read(const char *name, void *buf, size_t len)
{
	char path[128];
	ssize_t r;
	int fd;

	snprintf(path, sizeof(path), GK_DIR "/%s", name);
	fd = open(path, O_RDONLY | O_CLOEXEC);
	if (fd < 0)
		return -1;
	r = read(fd, buf, len);
	close(fd);
	return r == (ssize_t)len ? 0 : -1;
}

static int gk_write(const char *name, const void *buf, size_t len)
{
	char path[128], tmp[136];
	int fd;

	snprintf(path, sizeof(path), GK_DIR "/%s", name);
	snprintf(tmp, sizeof(tmp), "%s.new", path);
	fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
	if (fd < 0)
		return -1;
	if (write(fd, buf, len) != (ssize_t)len || fsync(fd)) {
		close(fd);
		unlink(tmp);
		return -1;
	}
	close(fd);
	return rename(tmp, path);
}

/* Credencial da MÁQUINA: cadastrada no Gatekeeper só na primeira vez. */
static int gk_ensure_enrolled(struct fpc_tee *t, uint8_t *secret,
			      uint8_t *handle)
{
	uint8_t cbor[128], *p = cbor, *rsp;
	const uint8_t *map, *h;
	size_t map_len, hlen;
	int fd, ret;

	if (!gk_read("secret", secret, GK_SECRET_LEN) &&
	    !gk_read("handle", handle, GK_HANDLE_LEN))
		return 0;

	if (mkdir(GK_DIR, 0700) && errno != EEXIST)
		return fail(t, -errno, GK_DIR ": %s", strerror(errno));
	fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
	if (fd < 0 || read(fd, secret, GK_SECRET_LEN) != GK_SECRET_LEN) {
		if (fd >= 0)
			close(fd);
		return fail(t, -EIO, "sem /dev/urandom");
	}
	close(fd);
	if (gk_write("secret", secret, GK_SECRET_LEN))
		return fail(t, -EIO, "não gravei " GK_DIR "/secret");

	p += cbor_head(p, 5, 2);
	p += cbor_uint_kv(p, 3, GK_UID);
	p += cbor_bytes_kv(p, 8, secret, GK_SECRET_LEN);
	rsp = calloc(1, GK_RSP_LEN);
	if (!rsp)
		return fail(t, -ENOMEM, "sem memória");
	ret = gk_call(t, GK_NEW_ENROLL, cbor, p - cbor, rsp, &map, &map_len);
	if (!ret && (cbor_map_get(map, map_len, 6, NULL, &h, &hlen) ||
		     hlen != GK_HANDLE_LEN))
		ret = fail(t, -EIO, "enroll do GK sem handle");
	if (!ret) {
		memcpy(handle, h, GK_HANDLE_LEN);
		if (gk_write("handle", handle, GK_HANDLE_LEN))
			ret = fail(t, -EIO, "não gravei " GK_DIR "/handle");
	}
	explicit_bzero(cbor, sizeof(cbor));
	explicit_bzero(rsp, GK_RSP_LEN);
	free(rsp);
	return ret;
}

static int gk_verify_hat(struct fpc_tee *t, uint64_t challenge, uint8_t *hat)
{
	uint8_t secret[GK_SECRET_LEN], handle[GK_HANDLE_LEN];
	uint8_t cbor[256], *p = cbor, *rsp = NULL;
	const uint8_t *map, *mac;
	size_t map_len, mac_len;
	uint64_t ver, ch, uid, aid, type, ts;
	uint32_t t32;
	int ret;

	ret = gk_ensure_enrolled(t, secret, handle);
	if (ret)
		goto out;
	p += cbor_head(p, 5, 4);
	p += cbor_uint_kv(p, 3, GK_UID);
	p += cbor_uint_kv(p, 4, challenge);
	p += cbor_bytes_kv(p, 6, handle, GK_HANDLE_LEN);
	p += cbor_bytes_kv(p, 9, secret, GK_SECRET_LEN);

	rsp = calloc(1, GK_RSP_LEN);
	if (!rsp) {
		ret = fail(t, -ENOMEM, "sem memória");
		goto out;
	}
	ret = gk_call(t, GK_NEW_VERIFY, cbor, p - cbor, rsp, &map, &map_len);
	if (ret)
		goto out;
	if (cbor_map_get(map, map_len, 11, &ver, NULL, NULL) ||
	    cbor_map_get(map, map_len, 4, &ch, NULL, NULL) ||
	    cbor_map_get(map, map_len, 12, &uid, NULL, NULL) ||
	    cbor_map_get(map, map_len, 13, &aid, NULL, NULL) ||
	    cbor_map_get(map, map_len, 14, &type, NULL, NULL) ||
	    cbor_map_get(map, map_len, 15, &ts, NULL, NULL) ||
	    cbor_map_get(map, map_len, 16, NULL, &mac, &mac_len) ||
	    mac_len != 32) {
		ret = fail(t, -EIO, "verify do GK incompleto");
		goto out;
	}
	if (ch != challenge) {
		ret = fail(t, -EIO, "desafio do token não confere");
		goto out;
	}
	/* mesma montagem do HAL: inteiros copiados como estão */
	hat[0] = (uint8_t)ver;
	memcpy(hat + 1, &ch, 8);
	memcpy(hat + 9, &uid, 8);
	memcpy(hat + 17, &aid, 8);
	t32 = (uint32_t)type;
	memcpy(hat + 25, &t32, 4);
	memcpy(hat + 29, &ts, 8);
	memcpy(hat + 37, mac, 32);
out:
	explicit_bzero(secret, sizeof(secret));
	explicit_bzero(handle, sizeof(handle));
	explicit_bzero(cbor, sizeof(cbor));
	if (rsp) {
		explicit_bzero(rsp, GK_RSP_LEN);
		free(rsp);
	}
	return ret;
}

/* keymaster 0x205 -> m3c5: chave HMAC dos tokens dentro do TA */
static int hw_auth_init(struct fpc_tee *t)
{
	uint32_t req[16] = { KM_GET_AUTH_TOKEN_KEY, 2 };
	uint32_t status, off, len;
	uint8_t *rsp, *b;
	int ret;

	rsp = calloc(1, GK_RSP_LEN);
	b = calloc(1, 0x1000);
	if (!rsp || !b) {
		ret = fail(t, -ENOMEM, "sem memória");
		goto out;
	}
	ret = km_send(t, req, sizeof(req), rsp);
	if (ret)
		goto out;
	memcpy(&status, rsp, 4);
	memcpy(&off, rsp + 4, 4);
	memcpy(&len, rsp + 8, 4);
	if (status || off < 12 || !len || off > 0x3c0 || len > 0x3c0 - off) {
		ret = fail(t, -EIO, "keymaster 0x205: %d/%u/%u",
			   (int32_t)status, off, len);
		goto out;
	}
	memcpy(b + 8, &len, 4);
	memcpy(b + 0xc, rsp + off, len);
	ret = ta_ok(t, 3, 5, b, 0x1000);
out:
	if (rsp) {
		explicit_bzero(rsp, GK_RSP_LEN);
		free(rsp);
	}
	if (b) {
		explicit_bzero(b, 0x1000);
		free(b);
	}
	return ret;
}

int fpc_tee_enrol_begin(struct fpc_tee *t)
{
	uint8_t b[0x70] = { 0 }, hat[GK_HAT_LEN];
	uint64_t challenge;
	int ret;

	ret = hw_auth_init(t);
	if (ret)
		return ret;
	ret = ta_ok(t, 3, 2, b, sizeof(b));	/* desafio do cadastro */
	if (ret)
		return ret;
	memcpy(&challenge, b + 8, 8);
	if (!challenge)
		return fail(t, -EIO, "desafio zero");
	ret = gk_verify_hat(t, challenge, hat);
	if (ret)
		return ret;

	memset(b, 0, sizeof(b));
	b[8] = GK_HAT_LEN;
	memcpy(b + 0xc, hat, GK_HAT_LEN);
	explicit_bzero(hat, sizeof(hat));
	ret = ta_ok(t, 3, 3, b, sizeof(b));	/* authorize_enrol */
	explicit_bzero(b, sizeof(b));
	if (ret)
		return ret;
	return ta_ok(t, 11, 1, b, sizeof(b));	/* begin_enrol */
}
