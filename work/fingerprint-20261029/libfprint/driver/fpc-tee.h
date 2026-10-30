/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
 * Núcleo do leitor FPC do Moto G60 (hanoip): fala com o fpctzapp no TEE pelo
 * /dev/qseecom-fpc (módulo qcom_qseecom_fpc) e com o keymaster64 residente
 * para obter o token do Gatekeeper que autoriza um cadastro.
 *
 * Protocolo e armadilhas: work/fingerprint-20261029/HANDOFF-20261030.md e
 * docs/kernel/PROTOCOLO-FPC-TA-20261029.md no repositório hanoip-mainline.
 *
 * Tudo aqui é bloqueante e sem estado global: o driver da libfprint chama
 * estas funções numa thread. Erros: negativo = errno; FPC_TEE_ERR_TA = o TA
 * recusou (status em t->last_status).
 */
#pragma once

#include <stddef.h>
#include <stdint.h>

#define FPC_TEE_ERR_TA		(-10000)
#define FPC_TEE_RETRY		1	/* captura ruim: tirar e tocar de novo */

struct fpc_tee {
	int fd;			/* /dev/qseecom-fpc */
	int gpio_out;		/* enable + reset */
	int irq_fd;		/* borda de subida da IRQ do sensor */
	uint32_t km_app_id;
	int32_t last_status;	/* rsp[0] da última chamada ao TA */
	char err[192];		/* última mensagem de erro, legível */
};

int fpc_tee_open(struct fpc_tee *t, const char *dev, const char *fwdir);
void fpc_tee_close(struct fpc_tee *t);

/* sensor init (m10c0) + bio init (m11c0) + banco do arquivo, se existir */
int fpc_tee_start(struct fpc_tee *t, const char *db_path);

/*
 * Espera o dedo (IRQ) e captura. @cancel_fd fica legível quando a operação
 * deve ser abandonada (-ECANCELED). Devolve 0, FPC_TEE_RETRY ou erro.
 */
int fpc_tee_capture(struct fpc_tee *t, int cancel_fd);

/* hw_auth + desafio + token do Gatekeeper + authorize_enrol + begin_enrol */
int fpc_tee_enrol_begin(struct fpc_tee *t);
/* uma amostra já capturada: *remaining = amostras que faltam */
int fpc_tee_enrol_sample(struct fpc_tee *t, uint32_t *remaining);
int fpc_tee_enrol_end(struct fpc_tee *t, uint32_t *id);

/* identifica a captura atual; *id = 0 se nada casou */
int fpc_tee_identify(struct fpc_tee *t, uint32_t *id);

/* ids dos templates no banco (o TA guarda no máximo 5); *count = capacidade */
int fpc_tee_list(struct fpc_tee *t, uint32_t *ids, uint32_t *count);
int fpc_tee_delete(struct fpc_tee *t, uint32_t id);

int fpc_tee_db_store(struct fpc_tee *t, const char *path);
