"""
pyclip mínimo para o Waydroid no Kali do hanoip (sessão Wayland/Phosh).

O Waydroid (tools/services/clipboard_manager.py) só usa pyclip.copy() e
pyclip.paste(); no Wayland o pyclip original chama wl-copy/wl-paste, que já
vêm do pacote wl-clipboard. O Kali não empacota o pyclip, então este módulo
faz o mesmo sem depender do PyPI.
"""
import subprocess

__all__ = ["copy", "paste", "clear"]


def copy(data, encoding="utf-8"):
    if isinstance(data, str):
        data = data.encode(encoding)
    subprocess.run(["wl-copy"], input=data, check=True, timeout=5)


def paste(text=True, encoding="utf-8"):
    out = subprocess.run(["wl-paste", "--no-newline"], capture_output=True,
                         timeout=5).stdout
    return out.decode(encoding, "replace") if text else out


def clear():
    subprocess.run(["wl-copy", "--clear"], check=False, timeout=5)
