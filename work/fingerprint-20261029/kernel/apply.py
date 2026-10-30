#!/usr/bin/env python3
"""Aplica o transporte qseecom-fpc numa árvore Linux (in-place, idempotente).

Uso: apply.py /src/linux

Não depende de patch(1): usa âncoras de texto verificadas e falha alto se algo
não casar, para nunca gerar uma árvore silenciosamente diferente da revisada.
"""
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'src')
TREE = None


def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()


def write(p, s):
    with open(p, 'w', encoding='utf-8') as f:
        f.write(s)


def rel(p):
    return os.path.relpath(p, TREE)


def copy_file(relpath):
    dst = os.path.join(TREE, relpath)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(os.path.join(SRC, relpath), dst)
    print('  cópia     %s' % relpath)


def sub_once(path, pattern, repl, marker, what):
    s = read(path)
    if marker in s:
        print('  já feito  %s (%s)' % (rel(path), what))
        return
    new, n = re.subn(pattern, repl, s, count=1, flags=re.S)
    if n != 1:
        sys.exit('ERRO: âncora de %s não casou em %s' % (what, rel(path)))
    write(path, new)
    print('  editado   %s (%s)' % (rel(path), what))


def sub_fn(path, pattern, fn, marker, what):
    s = read(path)
    if marker in s:
        print('  já feito  %s (%s)' % (rel(path), what))
        return
    new, n = re.subn(pattern, fn, s, count=1, flags=re.S)
    if n != 1:
        sys.exit('ERRO: âncora de %s não casou em %s' % (what, rel(path)))
    write(path, new)
    print('  editado   %s (%s)' % (rel(path), what))


def insert_after(path, anchor, text, marker):
    s = read(path)
    if marker in s:
        print('  já feito  %s' % rel(path))
        return
    if anchor not in s:
        sys.exit('ERRO: âncora não encontrada em %s' % rel(path))
    write(path, s.replace(anchor, anchor + text, 1))
    print('  editado   %s' % rel(path))


def insert_before(path, anchor, text, marker):
    s = read(path)
    if marker in s:
        print('  já feito  %s' % rel(path))
        return
    if anchor not in s:
        sys.exit('ERRO: âncora não encontrada em %s' % rel(path))
    write(path, s.replace(anchor, text + anchor, 1))
    print('  editado   %s' % rel(path))


def append(path, text, marker):
    s = read(path)
    if marker in s:
        print('  já feito  %s' % rel(path))
        return
    write(path, s + text)
    print('  anexado   %s' % rel(path))


def main():
    global TREE
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    TREE = sys.argv[1]
    if not os.path.isdir(os.path.join(TREE, 'drivers/firmware/qcom')):
        sys.exit('não parece uma árvore Linux: %s' % TREE)

    print('== arquivos novos')
    copy_file('include/uapi/misc/qseecom-fpc.h')
    copy_file('drivers/firmware/qcom/qcom_qseecom_fpc.c')

    scm = os.path.join(TREE, 'drivers/firmware/qcom/qcom_scm.c')

    print('== qcom_scm.c: enum dos comandos TZ')
    enum_add = (
        '\n'
        '\tQSEECOM_TZ_CMD_APP_START\t\t= 1, /* svc APP_MGR, owner QSEE_OS */\n'
        '\tQSEECOM_TZ_CMD_APP_SHUTDOWN\t\t= 2, /* svc APP_MGR, owner QSEE_OS */\n'
        '\tQSEECOM_TZ_CMD_APP_SEND_WL\t\t= 6, /* svc 0, owner TZ_APPS */\n'
        '\tQSEECOM_TZ_CMD_APP_REGION_NOTIFY\t= 5, /* svc APP_MGR, owner QSEE_OS */'
    )

    def add_enum(m):
        return m.group(1) + m.group(2) + enum_add + m.group(3)

    sub_fn(scm,
           r'(enum qcom_scm_qseecom_tz_cmd_app \{)(.*?)(\n\};)',
           add_enum,
           'QSEECOM_TZ_CMD_APP_START',
           'enum')

    print('== qcom_scm.c: app_start / app_shutdown / app_send_phys')
    frag = read(os.path.join(SRC, 'scm_qseecom_app.frag.c'))
    insert_before(scm,
                  'static const struct of_device_id qcom_scm_qseecom_allowlist[]',
                  frag + '\n',
                  'qcom_scm_qseecom_app_start(phys_addr_t')

    print('== qcom_scm.h: protótipos')
    hdr = os.path.join(TREE, 'include/linux/firmware/qcom/qcom_scm.h')
    protos = read(os.path.join(SRC, 'scm_qseecom_app.frag.h'))
    insert_after(hdr,
                 'int qcom_scm_qseecom_app_send(u32 app_id, void *req, size_t req_size,\n'
                 '\t\t\t      void *rsp, size_t rsp_size);\n',
                 protos,
                 'qcom_scm_qseecom_app_start(phys_addr_t')

    print('== Kconfig/Makefile')
    append(os.path.join(TREE, 'drivers/firmware/qcom/Kconfig'), '''
config QCOM_QSEECOM_FPC
	tristate "Legacy QSEECOM transport for HLOS-loaded TAs (FPC)"
	depends on QCOM_SCM
	help
	  Exposes /dev/qseecom-fpc, a minimal transport for Qualcomm TAs that the
	  non-secure world has to load itself (QSEOS_APP_START_COMMAND) and that
	  use the legacy 64-byte control block plus one out-of-band data region.

	  Required by the FPC fingerprint TA on the Motorola hanoip. It is not a
	  general-purpose QSEECOM replacement: no listeners, no RPMB, no keymaster
	  and no disk encryption support.
''', 'QCOM_QSEECOM_FPC')
    append(os.path.join(TREE, 'drivers/firmware/qcom/Makefile'),
           'obj-$(CONFIG_QCOM_QSEECOM_FPC)\t+= qcom_qseecom_fpc.o\n',
           'qcom_qseecom_fpc.o')

    print('OK')


if __name__ == '__main__':
    main()
