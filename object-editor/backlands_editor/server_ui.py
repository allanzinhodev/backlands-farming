"""Server item properties beside the visual object, keyed by ClientID."""
from __future__ import annotations

from pathlib import Path
import struct
import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog, ttk

from .server_project import ServerFiles

OTB_GROUPS = ("Nenhum", "Chão", "Contêiner", "Arma (legado)", "Munição (legado)",
              "Armadura (legado)", "Cargas", "Teleporte (legado)", "Campo (legado)",
              "Escrita (legado)", "Chave (legado)", "Splash", "Fluido", "Porta (legado)", "Obsoleto")
OTB_FLAGS = {0: "Bloqueia passagem", 1: "Bloqueia projéteis", 2: "Bloqueia caminho",
             3: "Tem altura", 4: "Usável", 5: "Coletável", 6: "Movível", 7: "Empilhável",
             13: "Sempre em cima", 14: "Legível", 15: "Rotacionável", 16: "Pendurável",
             17: "Vertical", 18: "Horizontal", 20: "Leitura à distância", 23: "Olhar através",
             24: "Animação", 26: "Forçar uso"}
OTB_PROPERTIES = ((0x14, "Velocidade", "H"), (0x21, "Cor minimapa", "H"),
                  (0x2A, "Luz: intensidade, cor", "HH"), (0x2B, "Ordem superior", "B"),
                  (0x2D, "Ware ID", "H"))


class ServerPanel(ttk.Frame):
    def __init__(self, parent, editor):
        super().__init__(parent, padding=8)
        self.editor = editor
        self.loading = False
        self.pending = False
        self._item_id = None
        canvas = tk.Canvas(self, highlightthickness=0, width=500, height=320)
        vertical = ttk.Scrollbar(self, orient="vertical", command=canvas.yview)
        horizontal = ttk.Scrollbar(self, orient="horizontal", command=canvas.xview)
        canvas.configure(yscrollcommand=vertical.set, xscrollcommand=horizontal.set)
        horizontal.pack(side="bottom", fill="x")
        vertical.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)
        content = ttk.Frame(canvas)
        window = canvas.create_window((0, 0), window=content, anchor="nw")
        content.bind("<Configure>", lambda _event: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", lambda event: canvas.itemconfigure(window, width=max(event.width, content.winfo_reqwidth())))
        self.canvas = canvas
        self.xml_path = tk.StringVar()
        self.otb_path = tk.StringVar()
        self.message = tk.StringVar()
        for variable, title, kind in ((self.xml_path, "items.xml", "xml"), (self.otb_path, "items.otb", "otb")):
            line = ttk.Frame(content)
            line.pack(fill="x", pady=2)
            ttk.Label(line, text=title, width=10).pack(side="left")
            ttk.Entry(line, textvariable=variable, state="readonly").pack(side="left", fill="x", expand=True)
            ttk.Button(line, text="Associar…", command=lambda k=kind: self.associate(k)).pack(side="left", padx=3)
        ttk.Label(content, text="O XML usa o ClientID do DAT. O ServerID do OTB é mantido como legado.").pack(anchor="w", pady=5)
        ttk.Label(content, textvariable=self.message, wraplength=700).pack(anchor="w", pady=3)
        actions = ttk.Frame(content)
        actions.pack(fill="x", pady=4)
        ttk.Button(actions, text="Aplicar dados do servidor", command=self.apply).pack(side="left")
        ttk.Button(actions, text="Criar registros ausentes", command=self.create_missing).pack(side="left", padx=4)
        ttk.Button(actions, text="Copiar flags do DAT → OTB", command=self.sync_dat).pack(side="left", padx=4)
        tabs = ttk.Notebook(content)
        tabs.pack(fill="both", expand=True, pady=4)
        xml_frame, otb_frame = ttk.Frame(tabs, padding=5), ttk.Frame(tabs, padding=5)
        tabs.add(xml_frame, text="Definição XML do item")
        tabs.add(otb_frame, text="Propriedades OTB")
        ttk.Label(xml_frame, text="Edite o elemento <item> completo: nome, peso, atributos e regras. O ID deve ser mantido.", wraplength=700).pack(anchor="w", pady=(0, 5))
        text_host = ttk.Frame(xml_frame)
        text_host.pack(fill="both", expand=True)
        self.xml_text = tk.Text(text_host, wrap="none", undo=True, height=12, width=50, font=("Consolas", 10))
        vertical = ttk.Scrollbar(text_host, command=self.xml_text.yview)
        horizontal = ttk.Scrollbar(xml_frame, orient="horizontal", command=self.xml_text.xview)
        self.xml_text.configure(yscrollcommand=vertical.set, xscrollcommand=horizontal.set)
        vertical.pack(side="right", fill="y")
        self.xml_text.pack(side="left", fill="both", expand=True)
        horizontal.pack(fill="x")
        self.xml_text.bind("<<Modified>>", self.text_modified)
        self.group_var = tk.StringVar(value="0 · Nenhum")
        row = ttk.Frame(otb_frame)
        row.pack(fill="x", pady=3)
        ttk.Label(row, text="Grupo").pack(side="left", padx=(0, 8))
        self.group_combo = ttk.Combobox(row, textvariable=self.group_var,
                     values=tuple(f"{i} · {name}" for i, name in enumerate(OTB_GROUPS)), state="readonly", width=28)
        self.group_combo.pack(side="left")
        self.group_var.trace_add("write", self.changed)
        flags = ttk.Frame(otb_frame)
        flags.pack(fill="x", pady=5)
        self.flags = {}
        self.otb_widgets = []
        for index, (bit, name) in enumerate(OTB_FLAGS.items()):
            variable = tk.BooleanVar()
            self.flags[bit] = variable
            button = ttk.Checkbutton(flags, text=name, variable=variable)
            button.grid(row=index // 3, column=index % 3, sticky="w", padx=3, pady=2)
            self.otb_widgets.append(button)
            variable.trace_add("write", self.changed)
        properties = ttk.Frame(otb_frame)
        properties.pack(fill="x", pady=5)
        self.properties = {}
        for row, (code, label, _fmt) in enumerate(OTB_PROPERTIES):
            enabled = tk.BooleanVar()
            variable = tk.StringVar()
            button = ttk.Checkbutton(properties, text=label, variable=enabled)
            button.grid(row=row, column=0, sticky="w")
            entry = ttk.Entry(properties, textvariable=variable, width=20)
            entry.grid(row=row, column=1, padx=8, pady=2)
            self.otb_widgets.extend((button, entry))
            enabled.trace_add("write", self.changed)
            variable.trace_add("write", self.changed)
            self.properties[code] = (enabled, variable)
        ttk.Label(otb_frame, text="Outras flags e atributos são preservados. A gravação acontece em Salvar (Ctrl+S).", wraplength=700).pack(anchor="w", pady=8)
        self.refresh()

    def changed(self, *_):
        if not self.loading:
            self.pending = True
            self.editor.mark_pending()

    def text_modified(self, _event=None):
        if self.xml_text.edit_modified():
            self.xml_text.edit_modified(False)
            self.changed()

    def refresh(self):
        self.loading = True
        linked = self.editor.project.server_files
        self.xml_path.set(str(linked.xml_path or "Não associado"))
        self.otb_path.set(str(linked.otb_path or "Não associado"))
        thing = self.editor.thing
        self._item_id = thing.id if thing and thing.category == 0 else None
        item = linked.xml_item(self._item_id) if self._item_id is not None else None
        records = linked.otb_items(self._item_id) if self._item_id is not None else []
        self.xml_text.configure(state="normal")
        self.xml_text.delete("1.0", "end")
        if item:
            self.xml_text.insert("1.0", item.to_fragment())
        self.xml_text.configure(state="normal" if item else "disabled")
        self.xml_text.edit_modified(False)
        record = records[0] if len(records) == 1 else None
        self.group_combo.configure(state="readonly" if record else "disabled")
        for widget in self.otb_widgets:
            widget.configure(state="normal" if record else "disabled")
        self.opaque_properties = set()
        self.group_var.set(f"{record.group} · {OTB_GROUPS[record.group] if record and record.group < len(OTB_GROUPS) else 'Desconhecido'}" if record else "0 · Nenhum")
        for bit, variable in self.flags.items():
            variable.set(bool(record and record.flags & (1 << bit)))
        for code, _label, fmt in OTB_PROPERTIES:
            enabled, variable = self.properties[code]
            data = record.get_attribute(code) if record else None
            valid = data is not None and len(data) == struct.calcsize("<" + fmt)
            if data is not None and not valid:
                self.opaque_properties.add(code)
            enabled.set(valid)
            variable.set(", ".join(str(n) for n in struct.unpack("<" + fmt, data)) if valid else "")
        if self._item_id is None:
            message = "Selecione um item para editar o servidor. Criaturas, efeitos e projéteis usam outros catálogos."
        else:
            otb = f"OTB ServerID {record.server_id} / ClientID {record.client_id}" if record else f"OTB: {len(records)} registros"
            message = f"ClientID {self._item_id} · {otb} · XML: {'encontrado' if item else 'sem registro (pode criar)'}"
        if linked.issues:
            message += "\n" + "\n".join(linked.issues)
        self.message.set(message)
        self.pending = False
        self.loading = False

    def apply(self):
        if not self.pending:
            return True
        try:
            if self._item_id is None:
                raise ValueError("Selecione um item do DAT.")
            original = self.editor.project.server_files
            # Keep catalog edits atomic with each other. No external file is written here.
            candidate = original.copy_for_edit(self._item_id)
            if candidate.xml_item(self._item_id):
                candidate.update_xml(self._item_id, self.xml_text.get("1.0", "end-1c"))
            matches = candidate.otb_items(self._item_id)
            if len(matches) == 1:
                record = matches[0]
                group = int(self.group_var.get().split(" · ", 1)[0])
                flags = record.flags
                for bit, value in self.flags.items():
                    flags = flags | (1 << bit) if value.get() else flags & ~(1 << bit)
                attrs = {}
                for code, _label, fmt in OTB_PROPERTIES:
                    enabled, value = self.properties[code]
                    if enabled.get():
                        numbers = tuple(int(text.strip(), 0) for text in value.get().split(","))
                        attrs[code] = struct.pack("<" + fmt, *numbers)
                    elif record.get_attribute(code) is not None and code not in self.opaque_properties:
                        # Removing an explicitly unchecked known attribute must not
                        # remove unknown fields or alter the ID attributes.
                        attrs[code] = None
                candidate.update_otb(self._item_id, group, flags, attrs)
        except (ValueError, struct.error) as error:
            messagebox.showerror("Dados do servidor inválidos", str(error), parent=self.editor.root)
            return False
        self.editor.project.server_files = candidate
        self.pending = False
        self.editor.mark_dirty()
        if self.editor.objects.exists(str(self._item_id)):
            self.editor.objects.item(str(self._item_id), values=(self._item_id, self.editor.thing_name(self.editor.thing)))
        self.message.set(f"ClientID {self._item_id}: alterações aplicadas em memória. Use Salvar para gravar.")
        return True

    def associate(self, kind):
        if not self.editor.apply_properties():
            return
        linked = self.editor.project.server_files
        if linked._edited_xml or linked._edited_otb:
            raise ValueError("Salve as alterações do servidor antes de trocar a associação.")
        path = filedialog.askopenfilename(parent=self.editor.root, title=f"Associar items.{kind}",
                                          filetypes=((f"Items {kind.upper()}", f"*.{kind}"),))
        if not path:
            return
        xml = Path(path) if kind == "xml" else linked.xml_path if linked.xml is not None else None
        otb = Path(path) if kind == "otb" else linked.otb_path if linked.otb is not None else None
        self.editor.project.server_files = ServerFiles.associate(xml, otb)
        self.editor.mark_dirty()
        self.refresh()
        self.editor.refresh_objects(self._item_id)

    def create_missing(self):
        thing = self.editor.thing
        if not thing or thing.category != 0 or not self.editor.apply_properties():
            return
        linked = self.editor.project.server_files
        if linked.xml_item(thing.id) and linked.otb_items(thing.id):
            self.message.set("Este item já possui registros XML e OTB.")
            return
        name = self.editor.thing_name(thing)
        if linked.xml_item(thing.id) is None:
            name = simpledialog.askstring("Nome do item no servidor", f"Nome para o ClientID {thing.id}", initialvalue=name, parent=self.editor.root)
            if name is None:
                return
        candidate = linked.copy_for_edit(thing.id)
        candidate.create_missing(thing.id, name)
        self.editor.project.server_files = candidate
        self.editor.mark_dirty()
        self.refresh()
        self.editor.refresh_objects(thing.id)

    def sync_dat(self):
        thing = self.editor.thing
        if not thing or thing.category != 0 or not self.editor.apply_properties():
            return
        candidate = self.editor.project.server_files.copy_for_edit(thing.id)
        candidate.sync_otb(thing)
        self.editor.project.server_files = candidate
        self.editor.mark_dirty()
        self.refresh()
