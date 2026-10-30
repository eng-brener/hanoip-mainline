#!/usr/bin/python3
"""hanoip-nfc — leitor NFC simples para o Kali no Moto G60 (Phosh).

Usa o neard (org.neard) sobre o nxp-nci do kernel. Mostra o adaptador, liga o
RF, inicia o poll e lista os cartões/tags detectados (tipo e UID).
"""
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk  # noqa: E402

NEARD = "org.neard"
ADAPTER_PATH = "/org/neard/nfc0"

# Tipo de tag -> nome amigável (propriedade Type do org.neard.Tag)
TAG_TYPES = {
    "Type 1": "ISO 14443-A (Type 1)",
    "Type 2": "ISO 14443-A (Type 2)",
    "Type 3": "FeliCa (Type 3)",
    "Type 4": "ISO 14443 (Type 4)",
    "Type 5": "ISO 15693 (Type 5)",
}


class NfcWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="NFC")
        self.set_default_size(360, 560)

        self.proxy = None
        self.adapter_props = []
        self.tags = {}

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(18)
        box.set_margin_bottom(18)
        box.set_margin_start(16)
        box.set_margin_end(16)

        title = Gtk.Label(label="NFC")
        title.add_css_class("title-1")
        box.append(title)

        self.status = Gtk.Label(label="Iniciando…")
        self.status.set_wrap(True)
        box.append(self.status)

        self.listbox = Gtk.ListBox()
        self.listbox.add_css_class("boxed-list")
        scroller = Gtk.ScrolledWindow()
        scroller.set_vexpand(True)
        scroller.set_child(self.listbox)
        box.append(scroller)

        self.detail = Gtk.Label(label="")
        self.detail.set_wrap(True)
        self.detail.set_selectable(True)
        self.detail.add_css_class("monospace")
        box.append(self.detail)

        self.button = Gtk.Button(label="Reiniciar leitura")
        self.button.connect("clicked", self.on_restart)
        box.append(self.button)

        self.set_content(box)

        GLib.timeout_add(500, self.connect_neard)

    # --- neard -----------------------------------------------------------
    def connect_neard(self):
        try:
            self.proxy = GLib.DBusProxy.new_sync(
                None, GLib.DBusProxyFlags.NONE, None,
                NEARD, ADAPTER_PATH, "org.neard.Adapter", None)
        except Exception as exc:  # noqa: BLE001
            self.set_status(f"neard indisponível ({exc}).\n"
                            "O serviço neard está rodando?")
            return False

        self.proxy.connect("g-properties-changed", self.on_props_changed)
        self.refresh_adapter()
        self.start_poll()
        return False

    def refresh_adapter(self):
        try:
            self.adapter_props = self.proxy.get_cached_property("Protocols")
        except Exception:  # noqa: BLE001
            self.adapter_props = None

    def call(self, method, *args):
        try:
            self.proxy.call_sync(method, GLib.Variant(*args) if args else None,
                                 GLib.DBusCallFlags.NONE, 5000, None)
            return True
        except Exception as exc:  # noqa: BLE001
            print(f"{method}: {exc}", file=sys.stderr)
            return False

    def set_powered(self, on=True):
        try:
            self.proxy.set_cached_property("Powered", GLib.Variant("b", on))
            self.proxy.call_sync(
                "org.freedesktop.DBus.Properties.Set",
                GLib.Variant("(ssv)", ("org.neard.Adapter", "Powered",
                                       GLib.Variant("b", on))),
                GLib.DBusCallFlags.NONE, 5000, None)
            return True
        except Exception as exc:  # noqa: BLE001
            print(f"power: {exc}", file=sys.stderr)
            return False

    def start_poll(self):
        self.set_powered(True)
        GLib.timeout_add(400, self._start_poll_loop)

    def _start_poll_loop(self):
        if self.call("StartPollLoop", ("s", "Initiator")):
            self.set_status("Lendo… encoste um cartão na traseira do celular.")
        else:
            self.set_status("Não consegui iniciar o poll (adaptador ligado?)")
        self.refresh_tags()
        return False

    def on_restart(self, _btn):
        self.call("StopPollLoop")
        GLib.timeout_add(300, self.start_poll)

    def on_props_changed(self, _proxy, _changed, _invalidated):
        self.refresh_tags()

    # --- tags ------------------------------------------------------------
    def refresh_tags(self):
        try:
            out = GLib.Variant  # noqa: F841  (keep import obvious)
            intro = self.proxy.call_sync(
                "org.freedesktop.DBus.Introspectable.Introspect", None,
                GLib.DBusCallFlags.NONE, 3000, None).unpack()
        except Exception:  # noqa: BLE001
            return

        import re
        paths = re.findall(r'node name="(tag\d+)"', intro)
        # limpa lista
        while self.listbox.get_first_child():
            self.listbox.remove(self.listbox.get_first_child())

        if not paths:
            row = Adw.ActionRow(title="Nenhum cartão no campo")
            row.add_css_class("dim-label")
            self.listbox.append(row)

        for name in paths:
            path = f"{ADAPTER_PATH}/{name}"
            props = {}
            try:
                tag = GLib.DBusProxy.new_sync(
                    None, GLib.DBusProxyFlags.NONE, None,
                    NEARD, path, "org.neard.Tag", None)
                for key in ("Type", "UID", "Protocol", "ReadOnly"):
                    val = tag.get_cached_property(key)
                    if val is not None:
                        props[key] = val.unpack()
            except Exception:  # noqa: BLE001
                pass

            ttype = props.get("Type", "?")
            label = TAG_TYPES.get(ttype, ttype)
            row = Adw.ActionRow(title=label, subtitle=name)
            self.listbox.append(row)

            uid = props.get("UID")
            if uid is not None:
                if isinstance(uid, (bytes, bytearray)):
                    uid = " ".join(f"{b:02x}" for b in uid)
                self.detail.set_text(f"{name}\nUID: {uid}\nTipo: {ttype}")
                self.status.set_text("Cartão detectado.")

    def set_status(self, text):
        self.status.set_text(text)


class NfcApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.hanoip.Nfc",
                         flags=0)
        self.win = None

    def do_activate(self):
        if not self.win:
            self.win = NfcWindow(self)
        self.win.present()


if __name__ == "__main__":
    NfcApp().run(sys.argv)
