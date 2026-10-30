/*
 * Driver para o leitor FPC do Motorola Moto G60 (hanoip), via TEE.
 *
 * O sensor não é acessível pelo Linux: quem captura, cadastra e compara é o
 * fpctzapp dentro do QSEE. Este driver só conversa com ele pelo
 * /dev/qseecom-fpc (módulo qcom_qseecom_fpc); toda a lógica de protocolo
 * fica em fpc-tee.c. O cadastro exige um token do Gatekeeper do próprio TEE,
 * obtido com uma credencial da máquina (ver fpc-tee.c).
 *
 * É um dispositivo do tipo VIRTUAL: o FpContext o cria quando a variável
 * FP_HANOIP_FPC está definida (o drop-in do fprintd faz isso). O valor pode
 * ser o caminho do dispositivo; qualquer outro valor usa /dev/qseecom-fpc.
 *
 * O TA guarda os templates num banco que o mundo normal só vê cifrado; ele
 * é salvo em HANOIP_FPC_DB depois de cada cadastro e recarregado na abertura.
 * Cada FpPrint carrega o id que o TA atribuiu ao template ("u").
 *
 * Copyright (C) 2026 hanoip-mainline
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#define FP_COMPONENT "hanoip_fpc"

#include <errno.h>

#include "drivers_api.h"
#include "fpc-tee.h"

#define HANOIP_FPC_DEV		"/dev/qseecom-fpc"
#define HANOIP_FPC_FW		"/mnt/ro/modem_a/image"
#define HANOIP_FPC_DB		"/var/lib/fpc-gk/templates.bin"
#define HANOIP_FPC_STAGES	12

#define HANOIP_FPC_MAX_PRINTS	5	/* limite do banco do TA */

struct _FpiDeviceHanoipFpc
{
  FpDevice       parent;
  struct fpc_tee tee;
  gint           enroll_done;
  guint32        enroll_remaining;
  guint32        ids[HANOIP_FPC_MAX_PRINTS];
  guint32        n_ids;
};

G_DECLARE_FINAL_TYPE (FpiDeviceHanoipFpc, fpi_device_hanoip_fpc, FPI,
                      DEVICE_HANOIP_FPC, FpDevice)
G_DEFINE_TYPE (FpiDeviceHanoipFpc, fpi_device_hanoip_fpc, FP_TYPE_DEVICE)

typedef int (*TeeFunc) (FpiDeviceHanoipFpc *self, int cancel_fd);

/* ------------------------------------------------------------ threads */

static void
tee_thread (GTask *task, gpointer source, gpointer data, GCancellable *cancellable)
{
  FpiDeviceHanoipFpc *self = source;
  TeeFunc fn = data;
  int cancel_fd = cancellable ? g_cancellable_get_fd (cancellable) : -1;
  int ret = fn (self, cancel_fd);

  if (cancellable && cancel_fd >= 0)
    g_cancellable_release_fd (cancellable);
  g_task_return_int (task, ret);
}

/* Roda @fn numa thread; @done recebe o resultado na thread principal. */
static void
tee_run (FpiDeviceHanoipFpc *self, TeeFunc fn, GAsyncReadyCallback done)
{
  GTask *task = g_task_new (self, fpi_device_get_cancellable (FP_DEVICE (self)),
                            done, NULL);

  g_task_set_task_data (task, fn, NULL);
  g_task_set_return_on_cancel (task, FALSE);
  g_task_run_in_thread (task, tee_thread);
  g_object_unref (task);
}

static int
tee_result (GAsyncResult *res)
{
  GError *error = NULL;
  gssize ret = g_task_propagate_int (G_TASK (res), &error);

  if (error)
    {
      g_error_free (error);
      return -ECANCELED;
    }
  return (int) ret;
}

/* Erro do núcleo -> GError da libfprint. */
static GError *
tee_error (FpiDeviceHanoipFpc *self, int ret)
{
  if (ret == -ECANCELED)
    return g_error_new_literal (G_IO_ERROR, G_IO_ERROR_CANCELLED, "Cancelled");
  if (ret == FPC_TEE_RETRY)
    return fpi_device_retry_new (FP_DEVICE_RETRY_REMOVE_FINGER);
  fp_warn ("%s (%d)", self->tee.err, ret);
  return fpi_device_error_new_msg (FP_DEVICE_ERROR_GENERAL, "%s",
                                   self->tee.err);
}

/* ------------------------------------------------------------ abrir/fechar */

static int
open_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  const char *env = fpi_device_get_virtual_env (FP_DEVICE (self));
  const char *dev = env && env[0] == '/' ? env : HANOIP_FPC_DEV;
  int ret = fpc_tee_open (&self->tee, dev, HANOIP_FPC_FW);

  if (!ret)
    ret = fpc_tee_start (&self->tee, HANOIP_FPC_DB);
  g_message ("open: %d (%s)", ret, ret ? self->tee.err : "ok");
  if (ret)
    fpc_tee_close (&self->tee);
  return ret;
}

static void
open_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  int ret = tee_result (res);

  fpi_device_open_complete (FP_DEVICE (self), ret ? tee_error (self, ret) : NULL);
}

static void
dev_open (FpDevice *dev)
{
  tee_run (FPI_DEVICE_HANOIP_FPC (dev), open_fn, open_done);
}

static void
dev_close (FpDevice *dev)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (dev);

  fpc_tee_close (&self->tee);
  fpi_device_close_complete (dev, NULL);
}

/* ------------------------------------------------------------ cadastro */

static void enroll_next (FpiDeviceHanoipFpc *self);

static int
enroll_begin_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  int ret;

  /*
   * O TA recusa begin_enrol (0xf11fc064) depois de uma identificação na
   * mesma sessão, e o fprintd sempre identifica antes de cadastrar (busca
   * de duplicata). Então o cadastro começa com um TA novo.
   */
  fpc_tee_close (&self->tee);
  ret = open_fn (self, cancel_fd);
  if (!ret)
    ret = fpc_tee_enrol_begin (&self->tee);

  g_message ("enroll begin: %d (TA 0x%08x)", ret, (guint32) self->tee.last_status);
  return ret;
}

static int
enroll_sample_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  int ret = fpc_tee_capture (&self->tee, cancel_fd);

  if (!ret)
    ret = fpc_tee_enrol_sample (&self->tee, &self->enroll_remaining);
  g_message ("enroll sample: %d (TA 0x%08x, restam %u)", ret,
             (guint32) self->tee.last_status, self->enroll_remaining);
  /* 8 = amostra parecida demais com as anteriores: não conta */
  if (!ret && self->tee.last_status == 8)
    ret = FPC_TEE_RETRY;
  return ret;
}

static int
enroll_end_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  guint32 id = 0;
  int ret = fpc_tee_enrol_end (&self->tee, &id);

  if (!ret)
    ret = fpc_tee_db_store (&self->tee, HANOIP_FPC_DB);
  g_message ("enroll end: %d (TA 0x%08x, id %u)", ret,
             (guint32) self->tee.last_status, id);
  /* o id volta pelo campo; 0 nunca é um id válido do TA */
  self->enroll_remaining = ret ? 0 : id;
  return ret;
}

static void
enroll_end_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  FpDevice *dev = FP_DEVICE (self);
  int ret = tee_result (res);
  FpPrint *print = NULL;

  if (ret || !self->enroll_remaining)
    {
      fpi_device_enroll_complete (dev, NULL, tee_error (self, ret ? ret : -EIO));
      return;
    }
  fpi_device_get_enroll_data (dev, &print);
  fpi_print_set_type (print, FPI_PRINT_RAW);
  fpi_print_set_device_stored (print, TRUE);
  g_object_set (print, "fpi-data", g_variant_new_uint32 (self->enroll_remaining),
                NULL);
  fp_info ("template %u cadastrado", self->enroll_remaining);
  fpi_device_enroll_complete (dev, g_object_ref (print), NULL);
}

static void
enroll_sample_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  FpDevice *dev = FP_DEVICE (self);
  int ret = tee_result (res);

  if (ret == FPC_TEE_RETRY)
    {
      fpi_device_enroll_progress (dev, self->enroll_done, NULL,
                                  tee_error (self, ret));
      enroll_next (self);
      return;
    }
  if (ret)
    {
      fpi_device_enroll_complete (dev, NULL, tee_error (self, ret));
      return;
    }

  /* O TA decide quantas amostras quer; a barra nunca passa do total. */
  if (self->enroll_remaining)
    self->enroll_done = MIN (self->enroll_done + 1, HANOIP_FPC_STAGES - 1);
  else
    self->enroll_done = HANOIP_FPC_STAGES;
  fpi_device_enroll_progress (dev, self->enroll_done, NULL, NULL);

  if (self->enroll_remaining)
    enroll_next (self);
  else
    tee_run (self, enroll_end_fn, enroll_end_done);
}

static void
enroll_next (FpiDeviceHanoipFpc *self)
{
  tee_run (self, enroll_sample_fn, enroll_sample_done);
}

static void
enroll_begin_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  int ret = tee_result (res);

  if (ret)
    {
      fpi_device_enroll_complete (FP_DEVICE (self), NULL, tee_error (self, ret));
      return;
    }
  enroll_next (self);
}

static void
dev_enroll (FpDevice *dev)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (dev);

  g_message ("enroll start");
  self->enroll_done = 0;
  self->enroll_remaining = 0;
  tee_run (self, enroll_begin_fn, enroll_begin_done);
}

/* ------------------------------------------------------------ verificar */

static int
match_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  guint32 id = 0;
  int ret = fpc_tee_capture (&self->tee, cancel_fd);

  if (!ret)
    ret = fpc_tee_identify (&self->tee, &id);
  g_message ("match: %d (TA 0x%08x, id %u)", ret, (guint32) self->tee.last_status, id);
  self->enroll_remaining = ret ? 0 : id;	/* reaproveitado: id casado */
  return ret;
}

static guint32
print_id (FpPrint *print)
{
  g_autoptr(GVariant) data = NULL;

  g_object_get (print, "fpi-data", &data, NULL);
  if (!data || !g_variant_is_of_type (data, G_VARIANT_TYPE_UINT32))
    return 0;
  return g_variant_get_uint32 (data);
}

static void
match_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  FpDevice *dev = FP_DEVICE (self);
  int ret = tee_result (res);
  guint32 id = self->enroll_remaining;

  if (fpi_device_get_current_action (dev) == FPI_DEVICE_ACTION_VERIFY)
    {
      FpPrint *print = NULL;

      if (ret == FPC_TEE_RETRY)
        {
          fpi_device_verify_report (dev, FPI_MATCH_ERROR, NULL, tee_error (self, ret));
          fpi_device_verify_complete (dev, NULL);
          return;
        }
      if (ret)
        {
          fpi_device_verify_complete (dev, tee_error (self, ret));
          return;
        }
      fpi_device_get_verify_data (dev, &print);
      fpi_device_verify_report (dev, id && id == print_id (print) ?
                                FPI_MATCH_SUCCESS : FPI_MATCH_FAIL, NULL, NULL);
      fpi_device_verify_complete (dev, NULL);
    }
  else
    {
      GPtrArray *prints = NULL;
      FpPrint *match = NULL;
      guint i;

      if (ret == FPC_TEE_RETRY)
        {
          fpi_device_identify_report (dev, NULL, NULL, tee_error (self, ret));
          fpi_device_identify_complete (dev, NULL);
          return;
        }
      if (ret)
        {
          fpi_device_identify_complete (dev, tee_error (self, ret));
          return;
        }
      fpi_device_get_identify_data (dev, &prints);
      for (i = 0; id && i < prints->len; i++)
        if (print_id (g_ptr_array_index (prints, i)) == id)
          match = g_ptr_array_index (prints, i);
      fpi_device_identify_report (dev, match, NULL, NULL);
      fpi_device_identify_complete (dev, NULL);
    }
}

static void
dev_match (FpDevice *dev)
{
  tee_run (FPI_DEVICE_HANOIP_FPC (dev), match_fn, match_done);
}

/* ------------------------------------------------------------ banco */

static int
list_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  self->n_ids = HANOIP_FPC_MAX_PRINTS;
  return fpc_tee_list (&self->tee, self->ids, &self->n_ids);
}

static void
list_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  FpDevice *dev = FP_DEVICE (self);
  int ret = tee_result (res);
  g_autoptr(GPtrArray) prints = NULL;
  guint i;

  if (ret)
    {
      fpi_device_list_complete (dev, NULL, tee_error (self, ret));
      return;
    }
  prints = g_ptr_array_new_with_free_func (g_object_unref);
  for (i = 0; i < self->n_ids; i++)
    {
      FpPrint *print = fp_print_new (dev);

      fpi_print_set_type (print, FPI_PRINT_RAW);
      fpi_print_set_device_stored (print, TRUE);
      g_object_set (print, "fpi-data", g_variant_new_uint32 (self->ids[i]), NULL);
      g_ptr_array_add (prints, print);
    }
  fpi_device_list_complete (dev, g_steal_pointer (&prints), NULL);
}

static void
dev_list (FpDevice *dev)
{
  tee_run (FPI_DEVICE_HANOIP_FPC (dev), list_fn, list_done);
}

static int
delete_fn (FpiDeviceHanoipFpc *self, int cancel_fd)
{
  int ret;

  /* mesma regra do cadastro: mexer no banco só com um TA novo */
  fpc_tee_close (&self->tee);
  ret = open_fn (self, cancel_fd);
  if (!ret)
    ret = fpc_tee_delete (&self->tee, self->ids[0]);
  if (!ret)
    ret = fpc_tee_db_store (&self->tee, HANOIP_FPC_DB);
  g_message ("delete %u: %d (TA 0x%08x)", self->ids[0], ret,
             (guint32) self->tee.last_status);
  return ret;
}

static void
delete_done (GObject *obj, GAsyncResult *res, gpointer data)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (obj);
  int ret = tee_result (res);
  GError *error = NULL;

  if (ret == FPC_TEE_ERR_TA)
    error = fpi_device_error_new (FP_DEVICE_ERROR_DATA_NOT_FOUND);
  else if (ret)
    error = tee_error (self, ret);
  fpi_device_delete_complete (FP_DEVICE (self), error);
}

static void
dev_delete (FpDevice *dev)
{
  FpiDeviceHanoipFpc *self = FPI_DEVICE_HANOIP_FPC (dev);
  FpPrint *print = NULL;

  fpi_device_get_delete_data (dev, &print);
  self->ids[0] = print_id (print);
  if (!self->ids[0])
    {
      fpi_device_delete_complete (dev, fpi_device_error_new (FP_DEVICE_ERROR_DATA_INVALID));
      return;
    }
  tee_run (self, delete_fn, delete_done);
}

/* ------------------------------------------------------------ classe */

static const FpIdEntry id_table[] = {
  { .virtual_envvar = "FP_HANOIP_FPC" },
  { .virtual_envvar = NULL }
};

static void
fpi_device_hanoip_fpc_init (FpiDeviceHanoipFpc *self)
{
  self->tee.fd = self->tee.gpio_out = self->tee.irq_fd = -1;
}

static void
fpi_device_hanoip_fpc_class_init (FpiDeviceHanoipFpcClass *klass)
{
  FpDeviceClass *dev_class = FP_DEVICE_CLASS (klass);

  dev_class->id = FP_COMPONENT;
  dev_class->full_name = "FPC fingerprint sensor (Moto G60, via TEE)";
  dev_class->type = FP_DEVICE_TYPE_VIRTUAL;
  dev_class->id_table = id_table;
  dev_class->scan_type = FP_SCAN_TYPE_PRESS;
  dev_class->nr_enroll_stages = HANOIP_FPC_STAGES;
  /* o TEE controla o sensor; não há modelo térmico a aplicar */
  dev_class->temp_hot_seconds = -1;

  dev_class->open = dev_open;
  dev_class->close = dev_close;
  dev_class->enroll = dev_enroll;
  dev_class->verify = dev_match;
  dev_class->identify = dev_match;
  dev_class->list = dev_list;
  dev_class->delete = dev_delete;

  fpi_device_class_auto_initialize_features (dev_class);
}
