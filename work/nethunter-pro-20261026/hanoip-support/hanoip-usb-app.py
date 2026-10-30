#!/usr/bin/env python3
"""hanoip-usb-app — modo da porta USB (Phosh / celular).

DECISÕES DE UI (por que é assim):
  - o mais importante numa tela de celular é "em que modo estou AGORA". Isso
    fica num cartão grande no topo (ícone + nome + resumo), não escondido numa
    marca de seleção no meio de uma lista;
  - trocar é UM toque na linha; sem "selecionar e depois aplicar";
  - o toast confirma e oferece DESFAZER (troca acidental custa um toque);
  - o estado técnico (Type-C, UDC, usb0, boost) fica num ExpanderRow fechado:
    quem quer detalhe abre, quem não quer não vê;
  - alvos de toque grandes (Adw.ActionRow ~60 px), nada de rádio pequeno;
  - aviso de que o USB cai por 1-3 s ao trocar, e dica do WiFi.

O app NÃO escreve em configfs: lê estado e pede a troca via pkexec.
"""
import os
import shutil
import subprocess
import sys
import threading
import traceback

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk  # noqa: E402

TOOL = "/usr/local/sbin/hanoip-usb-mode"
FIX = "/usr/local/sbin/hanoip-usb-fix"
LOG = os.path.expanduser("~/.cache/hanoip-usb-app.log")

MODOS = [
    ("combo",   "Rede + console", "network-wireless-symbolic",
     "Rede USB e console serial juntos. É o padrão."),
    ("net",     "Só rede", "network-wireless-symbolic",
     "Rede USB em 172.16.42.1, com DHCP para o computador."),
    ("serial",  "Só console", "utilities-terminal-symbolic",
     "Console em /dev/ttyACM*. Bom quando o resto falha."),
    ("storage", "Pendrive", "drive-harddisk-usb-symbolic",
     "O aparelho vira um pendrive (a partir de arquivo-imagem)."),
    ("hid",     "Teclado e mouse", "input-keyboard-symbolic",
     "Aparece como teclado USB em /dev/hidg0."),
    ("uvc",     "Webcam", "camera-web-symbolic",
     "Experimental: precisa do uvc-gadget para enviar imagem."),
    ("charge",  "Só carregar", "battery-good-symbolic",
     "Nenhuma função USB; apenas carrega."),
]
NOMES = {c: n for c, n, _, _ in MODOS}


def log(msg):
    try:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(msg.rstrip() + "\n")
    except Exception:
        pass


def rodar(args, timeout=90):
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return r.returncode, (r.stdout or "") + (r.stderr or "")
    except FileNotFoundError:
        return 127, f"não encontrei: {args[0]}"
    except subprocess.TimeoutExpired:
        return 124, "tempo esgotado"


def ler_status():
    rc, saida = rodar([TOOL, "status"], timeout=20)
    if rc != 0:
        log(f"status rc={rc}: {saida.strip()}")
        return None, {}
    salvo, estado = None, {}
    for linha in saida.splitlines():
        if ":" not in linha:
            continue
        k, v = linha.split(":", 1)
        k, v = k.strip(), v.strip()
        if k == "modo configurado":
            salvo = v
        elif k == "Type-C":
            estado["Papel Type-C"] = v
        elif k == "UDC":
            estado["Controlador (UDC)"] = v
        elif k == "usb0":
            estado["Rede usb0"] = v or "sem endereço"
        elif k.startswith("boost de VBUS"):
            estado["Boost de VBUS"] = v
        elif k == "Gadget":
            estado["Gadget"] = v
        elif k == "Funções":
            estado["Funções"] = v or "nenhuma"
        elif k == "Última troca":
            estado["Última troca"] = v
    return salvo, estado


class Janela(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Porta USB")
        self.set_default_size(400, 800)
        self.modo = None
        self.aplicando = False
        self.linhas = {}
        self.rows = {}

        header = Adw.HeaderBar()
        titulo = Gtk.Label(label="Porta USB")
        titulo.add_css_class("title")
        header.set_title_widget(titulo)
        self.spinner = Adw.Spinner(); self.spinner.set_visible(False)
        header.pack_start(self.spinner)
        b = Gtk.Button(icon_name="view-refresh-symbolic")
        b.set_tooltip_text("Atualizar")
        b.connect("clicked", lambda *_: self.atualizar())
        header.pack_end(b)

        self.banner = Adw.Banner(
            title="Trocar o modo reinicia o USB por 1–3 s. "
                  "Se estiver no cabo, use o WiFi para comandar.")
        self.banner.set_revealed(True)

        # ---------- cartão do modo atual (o que se olha primeiro)
        cartao = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        cartao.add_css_class("card")
        cartao.set_margin_top(12); cartao.set_margin_bottom(6)
        cartao.set_margin_start(12); cartao.set_margin_end(12)
        self.icone = Gtk.Image.new_from_icon_name("network-wireless-symbolic")
        self.icone.set_pixel_size(40)
        self.icone.set_valign(Gtk.Align.CENTER)
        cartao.append(self.icone)
        texto = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        texto.set_valign(Gtk.Align.CENTER)
        texto.set_hexpand(True)
        self.titulo_atual = Gtk.Label(label="—")
        self.titulo_atual.set_xalign(0)
        self.titulo_atual.add_css_class("title-2")
        self.resumo_atual = Gtk.Label(label="lendo…")
        self.resumo_atual.set_xalign(0)
        self.resumo_atual.set_wrap(True)
        self.resumo_atual.add_css_class("dim-label")
        self.resumo_atual.add_css_class("caption")
        texto.append(self.titulo_atual)
        texto.append(self.resumo_atual)
        cartao.append(texto)
        self.selo = Gtk.Label(label="ATIVO")
        self.selo.add_css_class("caption")
        self.selo.add_css_class("accent")
        self.selo.set_valign(Gtk.Align.CENTER)
        cartao.append(self.selo)

        pagina = Adw.PreferencesPage()
        grupo_top = Adw.PreferencesGroup()
        grupo_top.add(cartao)

        # ---------- lista para trocar
        grupo_modos = Adw.PreferencesGroup(
            title="Trocar para",
            description="Um toque troca. Dá para desfazer no aviso.")
        pagina.add(grupo_top)
        pagina.add(grupo_modos)

        for chave, nome, icone, dica in MODOS:
            linha = Adw.ActionRow(title=nome, subtitle=dica, activatable=True)
            img = Gtk.Image.new_from_icon_name(icone)
            linha.add_prefix(img)
            marca = Gtk.Label(label="atual")
            marca.add_css_class("caption")
            marca.add_css_class("dim-label")
            marca.set_valign(Gtk.Align.CENTER)
            marca.set_visible(False)
            linha.add_suffix(marca)
            linha.connect("activated", self.ao_escolher, chave)
            grupo_modos.add(linha)
            self.rows[chave] = (linha, marca)

        # ---------- estado técnico (fechado)
        grupo_estado = Adw.PreferencesGroup()
        pagina.add(grupo_estado)
        self.expandir = Adw.ExpanderRow(
            title="Estado do hardware",
            subtitle="Papel Type-C, controlador, rede e VBUS")
        grupo_estado.add(self.expandir)
        for chave in ("Papel Type-C", "Controlador (UDC)", "Rede usb0",
                      "Boost de VBUS", "Gadget", "Funções", "Última troca"):
            l = Adw.ActionRow(title=chave, subtitle="—")
            l.set_subtitle_selectable(True)
            self.expandir.add_row(l)
            self.linhas[chave] = l

        # ---------- saída de emergência
        grupo_ajuda = Adw.PreferencesGroup()
        pagina.add(grupo_ajuda)
        ajuda = Adw.ActionRow(title="O USB não voltou",
                              subtitle="Revincula o controlador (hanoip-usb-fix fix)",
                              activatable=True)
        ajuda.add_prefix(Gtk.Image.new_from_icon_name("emblem-important-symbolic"))
        ajuda.connect("activated", self.ao_recuperar)
        grupo_ajuda.add(ajuda)

        self.toasts = Adw.ToastOverlay()
        caixa = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        caixa.append(self.banner)
        caixa.append(pagina)
        self.toasts.set_child(caixa)

        vista = Adw.ToolbarView()
        vista.add_top_bar(header)
        vista.set_content(self.toasts)
        self.set_content(vista)

        self.atualizar()
        GLib.timeout_add_seconds(4, self.periodico)

    # ------------------------------------------------------------ estado
    def periodico(self):
        if not self.aplicando:
            self.atualizar()
        return True

    def atualizar(self):
        salvo, estado = ler_status()
        if salvo:
            self.modo = salvo
            nome = NOMES.get(salvo, salvo)
            icone = next((i for c, _, i, _ in MODOS if c == salvo),
                         "network-wireless-symbolic")
            self.titulo_atual.set_text(nome)
            self.icone.set_from_icon_name(icone)
            resumo = estado.get("Rede usb0") or ""
            if salvo in ("combo", "net") and resumo:
                self.resumo_atual.set_text("usb0 · " + resumo)
            elif salvo == "charge":
                self.resumo_atual.set_text("sem função USB; só carregando")
            else:
                self.resumo_atual.set_text(estado.get("Papel Type-C", ""))
            for chave, (_linha, marca) in self.rows.items():
                marca.set_visible(chave == salvo)
        for chave, l in self.linhas.items():
            l.set_subtitle(estado.get(chave, "—"))
        return False

    # ------------------------------------------------------------- ações
    def ao_escolher(self, _linha, chave):
        if self.aplicando:
            return
        if chave == self.modo:
            self.toasts.add_toast(Adw.Toast.new("Esse já é o modo atual."))
            return
        self.aplicar(chave, self.modo)

    def aplicar(self, chave, anterior=None):
        if not shutil.which("pkexec"):
            self.erro("Falta o pkexec",
                      f"Use o terminal:\n\nsudo {TOOL} set {chave}")
            return
        self.aplicando = True
        self.spinner.set_visible(True)
        self.banner.set_title(f"Aplicando “{NOMES.get(chave, chave)}”… "
                              "o USB pode cair por alguns segundos.")
        threading.Thread(target=self._trabalho, args=(chave, anterior),
                         daemon=True).start()

    def _trabalho(self, chave, anterior):
        rc, saida = rodar(["pkexec", TOOL, "set", chave])
        GLib.idle_add(self.terminou, chave, anterior, rc, saida)

    def terminou(self, chave, anterior, rc, saida):
        self.aplicando = False
        self.spinner.set_visible(False)
        self.banner.set_title("Trocar o modo reinicia o USB por 1–3 s. "
                              "Se estiver no cabo, use o WiFi para comandar.")
        log(f"set {chave} rc={rc}: {saida.strip()}")
        if rc == 0:
            toast = Adw.Toast.new(f"Agora: {NOMES.get(chave, chave)}")
            if anterior and anterior != chave:
                toast.set_button_label("Desfazer")
                toast.connect("button-clicked",
                              lambda *_: self.aplicar(anterior, chave))
            self.toasts.add_toast(toast)
            self.atualizar()
        elif rc in (126, 127):
            self.erro("Sem autorização",
                      "O sistema não autorizou pelo app.\nNo terminal:\n\n"
                      f"sudo {TOOL} set {chave}")
        else:
            self.erro("Não deu certo", f"(rc={rc})\n\n{saida.strip()[:700]}")
        return False

    def ao_recuperar(self, *_):
        if not shutil.which("pkexec"):
            self.erro("Falta o pkexec", f"No terminal:\n\nsudo {FIX} fix")
            return
        threading.Thread(target=self._recuperar, daemon=True).start()

    def _recuperar(self):
        rc, saida = rodar(["pkexec", FIX, "fix"], timeout=60)

        def fim():
            if rc == 0:
                self.toasts.add_toast(Adw.Toast.new("Controlador revinculado."))
            else:
                self.erro("Não deu certo", f"(rc={rc})\n\n{saida.strip()[:600]}")
            self.atualizar()
            return False
        GLib.idle_add(fim)

    def erro(self, titulo, corpo):
        dlg = Adw.AlertDialog(heading=titulo, body=corpo)
        dlg.add_response("ok", "Entendi")
        dlg.add_response("copiar", "Copiar")
        dlg.connect("response", self._resposta, corpo)
        dlg.present(self)

    def _resposta(self, _dlg, resp, corpo):
        if resp == "copiar":
            self.get_clipboard().set(corpo)
            self.toasts.add_toast(Adw.Toast.new("Copiado."))


class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.hanoip.UsbMode")
        self.win = None

    def do_activate(self):
        if self.win is None:
            self.win = Janela(self)      # referência forte: não encerra
        self.win.present()


if __name__ == "__main__":
    try:
        sys.exit(App().run(sys.argv))
    except Exception:
        log("main:\n" + traceback.format_exc())
        raise
