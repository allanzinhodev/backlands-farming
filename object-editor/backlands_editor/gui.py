"""Backlands Asset Studio: a local DAT/SPR 8.60 editor with native 16px sprites."""
from __future__ import annotations

import copy
import csv
import io
import sys
import time
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, simpledialog, ttk

from PIL import Image, ImageTk

from .animation import (
    AnimationPlayback, DEFAULT_DURATION, create_group, duplicate_frame, enable_frame_durations,
    enable_frame_groups, insert_frame, move_frame, remove_frame, remove_group,
    validate_animation, validate_group_types,
)
from .animation_ui import AnimationPanel
from .formats import Attribute, FLAG_SPECS, FormatOptions, FrameGroup
from .project import Project
from .settings import remember_project, startup_project
from .widgets import PixelEditor, checker

CATEGORIES = ("Itens", "Criaturas", "Efeitos", "Projéteis")
DIMENSIONS = (
    ("width", "Largura (tiles)"), ("height", "Altura (tiles)"),
    ("exact_size", "Tamanho exato (px)"), ("layers", "Camadas"),
    ("pattern_x", "Padrões X"), ("pattern_y", "Padrões Y"),
    ("pattern_z", "Padrões Z"), ("frames", "Quadros"),
)


class FormatDialog(simpledialog.Dialog):
    def __init__(self, parent, title="Novo projeto 8.60 / 16×16"):
        self.options = None
        super().__init__(parent, title)

    def body(self, master):
        ttk.Label(master, text="Protocolo 8.60 · sprites nativos de 16×16 pixels", padding=8).grid(columnspan=2, sticky="w")
        ttk.Label(master, text="Escolha as extensões usadas pelos seus arquivos.").grid(columnspan=2, sticky="w", pady=8)
        self.variables = {}
        for row, (key, text) in enumerate((
            ("extended", "IDs de sprites de 32 bits (extended)"),
            ("transparency", "Alpha parcial (RGBA)"),
            ("frame_durations", "Duração por quadro"),
            ("frame_groups", "Grupos de animação de criaturas"),
        ), 2):
            variable = tk.BooleanVar(value=False)
            self.variables[key] = variable
            ttk.Checkbutton(master, text=text, variable=variable).grid(row=row, columnspan=2, sticky="w", pady=4)
        ttk.Label(master, text="Sem OTFI, só prossiga se a origem já for 16×16.\nArquivos 32×32 devem ser convertidos antes.", padding=8).grid(row=6, columnspan=2, sticky="w")

    def apply(self):
        self.options = FormatOptions(**{key: value.get() for key, value in self.variables.items()})


class Editor:
    def __init__(self, root: tk.Tk, path: Path | None = None):
        self.root = root
        self.project = Project.new()
        self.category = 0
        self.thing = None
        self.group_index = 0
        self.sprite_id = 0
        self.page = 0
        self.dirty = False
        self.pending = False
        self.loading = False
        self.undo_stack = []
        self.redo_stack = []
        self.library_images = []
        self.preview_image = None
        self.playing = False
        self.animation_job = None
        self.status = tk.StringVar(value="Novo projeto · sprites de 16×16 · pronto")
        root.geometry("1440x920")
        root.minsize(1180, 740)
        root.protocol("WM_DELETE_WINDOW", self.close)
        root.report_callback_exception = self.callback_error
        style = ttk.Style(root)
        if "clam" in style.theme_names():
            style.theme_use("clam")
        style.configure("TButton", padding=(8, 5))
        style.configure("Title.TLabel", font=("Segoe UI", 16, "bold"))
        self.build_menu()
        self.build_ui()
        for shortcut, callback in (("<Control-n>", self.new), ("<Control-o>", self.open),
                                   ("<Control-s>", self.save), ("<Control-Shift-S>", self.save_as),
                                   ("<Control-z>", self.undo), ("<Control-y>", self.redo)):
            root.bind(shortcut, lambda _event, action=callback: action())
        self.refresh_objects(100)
        self.refresh_library()
        self.update_title()
        if path:
            root.after(50, lambda: self.open_path(path))

    def callback_error(self, exception, value, traceback):
        # Keep a traceback for developers while making errors visible in the GUI.
        import traceback as tb
        tb.print_exception(exception, value, traceback)
        messagebox.showerror("Não foi possível concluir", str(value), parent=self.root)
        self.status.set(str(value))

    def build_menu(self):
        menu = tk.Menu(self.root)
        file = tk.Menu(menu, tearoff=False)
        for title, action, shortcut in (
            ("Novo…", self.new, "Ctrl+N"), ("Abrir OTFI…", self.open, "Ctrl+O"),
            ("Abrir pasta…", self.open_directory, ""), ("Salvar", self.save, "Ctrl+S"),
            ("Salvar como…", self.save_as, "Ctrl+Shift+S"),
        ):
            file.add_command(label=title, command=action, accelerator=shortcut)
        file.add_separator()
        file.add_command(label="Sair", command=self.close)
        menu.add_cascade(label="Arquivo", menu=file)
        edit = tk.Menu(menu, tearoff=False)
        edit.add_command(label="Desfazer pixels", command=self.undo, accelerator="Ctrl+Z")
        edit.add_command(label="Refazer pixels", command=self.redo, accelerator="Ctrl+Y")
        edit.add_separator()
        edit.add_command(label="Novo objeto", command=self.add_thing)
        edit.add_command(label="Duplicar objeto", command=lambda: self.add_thing(True))
        menu.add_cascade(label="Editar", menu=edit)
        help_menu = tk.Menu(menu, tearoff=False)
        help_menu.add_command(label="Sobre / compatibilidade", command=self.about)
        menu.add_cascade(label="Ajuda", menu=help_menu)
        self.root.configure(menu=menu)

    def build_ui(self):
        header = ttk.Frame(self.root, padding=(14, 10))
        header.pack(fill="x")
        ttk.Label(header, text="Backlands Asset Studio", style="Title.TLabel").pack(side="left")
        ttk.Label(header, text="DAT + SPR  /  8.60  /  16×16", padding=(16, 0)).pack(side="left")
        for text, action in (("Novo", self.new), ("Abrir", self.open), ("Salvar", self.save), ("Salvar como", self.save_as)):
            ttk.Button(header, text=text, command=action).pack(side="left", padx=3)
        panes = ttk.Panedwindow(self.root, orient="horizontal")
        panes.pack(fill="both", expand=True, padx=10)
        left, center, right = (ttk.Frame(panes) for _ in range(3))
        panes.add(left, weight=0)
        panes.add(center, weight=1)
        panes.add(right, weight=0)
        left.configure(width=235)
        right.configure(width=340)
        self.build_objects(left)
        self.build_center(center)
        self.build_properties(right)
        self.animation_panel = AnimationPanel(self.center_notebook, self)
        self.center_notebook.add(self.animation_panel, text="Animação / frame groups")
        ttk.Label(self.root, textvariable=self.status, padding=(12, 7), relief="sunken", anchor="w").pack(fill="x", side="bottom")

    def build_objects(self, parent):
        ttk.Label(parent, text="OBJETOS", padding=(4, 8)).pack(anchor="w")
        self.category_var = tk.StringVar(value=CATEGORIES[0])
        category = ttk.Combobox(parent, textvariable=self.category_var, values=CATEGORIES, state="readonly", width=24)
        category.pack(fill="x", padx=4)
        category.bind("<<ComboboxSelected>>", self.change_category)
        search = ttk.Frame(parent, padding=4)
        search.pack(fill="x")
        self.search = tk.StringVar()
        ttk.Entry(search, textvariable=self.search, width=16).pack(side="left", fill="x", expand=True)
        ttk.Button(search, text="ID / nome", command=self.filter_objects).pack(side="left", padx=2)
        self.search.trace_add("write", lambda *_: self.filter_objects())
        frame = ttk.Frame(parent)
        frame.pack(fill="both", expand=True, padx=4)
        self.objects = ttk.Treeview(frame, columns=("id", "name"), show="headings", selectmode="browse", height=18)
        self.objects.heading("id", text="ID")
        self.objects.heading("name", text="Objeto / mercado")
        self.objects.column("id", width=55, stretch=False)
        self.objects.column("name", width=145)
        scroll = ttk.Scrollbar(frame, orient="vertical", command=self.objects.yview)
        self.objects.configure(yscrollcommand=scroll.set)
        scroll.pack(side="right", fill="y")
        self.objects.pack(side="left", fill="both", expand=True)
        self.objects.bind("<<TreeviewSelect>>", self.select_thing)
        buttons = ttk.Frame(parent, padding=4)
        buttons.pack(fill="x")
        ttk.Button(buttons, text="+ Novo", command=self.add_thing).pack(side="left", expand=True, fill="x")
        ttk.Button(buttons, text="Duplicar", command=lambda: self.add_thing(True)).pack(side="left", expand=True, fill="x", padx=3)
        ttk.Label(parent, text="IDs existentes são preservados.\nItens começam em 100.", padding=6).pack(anchor="w")

    def build_center(self, parent):
        notebook = ttk.Notebook(parent)
        notebook.pack(fill="both", expand=True, padx=8, pady=8)
        preview = ttk.Frame(notebook, padding=8)
        notebook.add(preview, text="Prévia do objeto")
        self.pixel = PixelEditor(notebook, self.pixel_changed)
        notebook.add(self.pixel, text="Editor de pixels 16×16")
        self.center_notebook = notebook
        controls = ttk.Frame(preview)
        controls.pack(fill="x")
        ttk.Label(controls, text="Grupo").pack(side="left")
        self.group_var = tk.IntVar(value=0)
        self.group_combo = ttk.Combobox(controls, textvariable=self.group_var, width=3, state="readonly", values=(0,))
        self.group_combo.pack(side="left", padx=4)
        self.group_combo.bind("<<ComboboxSelected>>", self.change_group)
        self.play_button = ttk.Button(controls, text="▶ Animar", command=self.toggle_animation)
        self.play_button.pack(side="left", padx=4)
        ttk.Label(controls, text="Zoom").pack(side="left", padx=(10, 0))
        self.preview_zoom = tk.IntVar(value=6)
        zoom = ttk.Combobox(controls, textvariable=self.preview_zoom, values=(1, 2, 3, 4, 6, 8, 12), width=3, state="readonly")
        zoom.pack(side="left", padx=4)
        zoom.bind("<<ComboboxSelected>>", lambda _e: self.draw_preview())
        self.preview_canvas = tk.Canvas(preview, background="#e8edf1", height=260, highlightthickness=0)
        self.preview_canvas.pack(fill="both", expand=True, pady=8)
        self.preview_canvas.bind("<Configure>", lambda _e: self.draw_preview())
        self.selectors = {}
        selector_bar = ttk.Frame(preview)
        selector_bar.pack(fill="x")
        for key, text in (("frame", "Quadro"), ("pattern_x", "X"), ("pattern_y", "Y"), ("pattern_z", "Z")):
            ttk.Label(selector_bar, text=text).pack(side="left", padx=(4, 2))
            variable = tk.IntVar(value=0)
            combo = ttk.Combobox(selector_bar, textvariable=variable, values=(0,), width=3, state="readonly")
            combo.pack(side="left", padx=(0, 3))
            combo.bind("<<ComboboxSelected>>", lambda _e: self.draw_preview())
            self.selectors[key] = (variable, combo)
        ttk.Button(preview, text="Exportar PNG da prévia", command=self.export_preview).pack(anchor="w", pady=(8, 0))
        library = ttk.LabelFrame(parent, text="Biblioteca de sprites 16×16", padding=6)
        library.pack(fill="x", padx=8, pady=(0, 6))
        bar = ttk.Frame(library)
        bar.pack(fill="x")
        ttk.Button(bar, text="◀", width=3, command=lambda: self.change_page(-1)).pack(side="left")
        self.page_text = tk.StringVar()
        ttk.Label(bar, textvariable=self.page_text).pack(side="left", padx=5)
        ttk.Button(bar, text="▶", width=3, command=lambda: self.change_page(1)).pack(side="left")
        ttk.Button(bar, text="+ Vazio", command=self.add_sprite).pack(side="left", padx=3)
        ttk.Button(bar, text="Importar PNG…", command=self.import_sprites).pack(side="left", padx=3)
        self.library_canvas = tk.Canvas(library, width=480, height=184, background="#f5f7f9", highlightthickness=0)
        self.library_canvas.pack(fill="x", pady=6)
        self.library_canvas.bind("<Button-1>", self.click_library)
        self.library_canvas.bind("<Double-Button-1>", self.link_sprite)
        self.selected_text = tk.StringVar(value="Sprite 0 (transparente)")
        actions = ttk.Frame(library)
        actions.pack(fill="x")
        ttk.Label(actions, textvariable=self.selected_text).pack(side="left")
        ttk.Button(actions, text="Ir ao ID…", command=self.goto_sprite).pack(side="right")
        actions = ttk.Frame(library)
        actions.pack(fill="x", pady=(4, 0))
        for text, action in (("Vincular ao slot", self.link_sprite), ("Substituir PNG", self.replace_sprite), ("Exportar PNG", self.export_sprite)):
            ttk.Button(actions, text=text, command=action).pack(side="left", padx=2)

    def build_properties(self, parent):
        ttk.Label(parent, text="PROPRIEDADES DO OBJETO", padding=(4, 8)).pack(anchor="w")
        ttk.Button(parent, text="Aplicar propriedades", command=self.apply_properties).pack(fill="x", padx=4, pady=(0, 6))
        notebook = ttk.Notebook(parent)
        notebook.pack(fill="both", expand=True, padx=4, pady=(0, 6))
        geometry, flags, slots = (ttk.Frame(notebook, padding=8) for _ in range(3))
        notebook.add(geometry, text="Geometria")
        notebook.add(flags, text="Flags")
        notebook.add(slots, text="Sprites / slots")
        self.dim_vars = {}
        self.dim_widgets = {}
        for row, (key, text) in enumerate(DIMENSIONS):
            ttk.Label(geometry, text=text).grid(row=row, column=0, sticky="w", pady=4)
            variable = tk.IntVar(value=16 if key == "exact_size" else 1)
            spin = ttk.Spinbox(geometry, textvariable=variable, from_=1, to=255, width=7)
            spin.grid(row=row, column=1, padx=8)
            self.dim_widgets[key] = spin
            variable.trace_add("write", self.mark_pending)
            self.dim_vars[key] = variable
        self.group_type = tk.IntVar(value=0)
        self.group_type.trace_add("write", self.mark_pending)
        self.animation_meta = tk.StringVar(value="0, 0, 0")
        self.animation_meta.trace_add("write", self.mark_pending)
        self.duration_text = tk.StringVar()
        self.duration_text.trace_add("write", self.mark_pending)
        ttk.Label(geometry, text="Edite grupos, quadros e tempos na aba\nAnimação / frame groups.").grid(row=8, columnspan=2, sticky="w", pady=8)
        for text, action in (("Importar folha do objeto…", self.import_thing_sheet), ("Exportar folha do objeto…", self.export_thing_sheet)):
            ttk.Button(geometry, text=text, command=action).grid(columnspan=2, sticky="ew", pady=3)
        ttk.Label(geometry, text="Ao redimensionar, slots nas mesmas\ncoordenadas são preservados.").grid(columnspan=2, sticky="w", pady=8)
        flag_canvas = tk.Canvas(flags, highlightthickness=0, width=290)
        scrollbar = ttk.Scrollbar(flags, command=flag_canvas.yview)
        flag_canvas.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side="right", fill="y")
        flag_canvas.pack(side="left", fill="both", expand=True)
        rows = ttk.Frame(flag_canvas)
        flag_canvas.create_window((0, 0), window=rows, anchor="nw")
        rows.bind("<Configure>", lambda _e: flag_canvas.configure(scrollregion=flag_canvas.bbox("all")))
        self.flag_vars = {}
        for code, (name, fields) in FLAG_SPECS.items():
            row = ttk.Frame(rows, padding=(0, 3))
            row.pack(fill="x")
            enabled = tk.BooleanVar(value=False)
            value = tk.StringVar()
            ttk.Checkbutton(row, text=f"{code:02X}  {name}", variable=enabled).pack(anchor="w")
            if fields:
                ttk.Entry(row, textvariable=value, width=30).pack(anchor="w", padx=(18, 0))
                ttk.Label(row, text=", ".join(fields), wraplength=260).pack(anchor="w", padx=(18, 0))
            enabled.trace_add("write", self.mark_pending)
            value.trace_add("write", self.mark_pending)
            self.flag_vars[code] = (enabled, value)
        ttk.Label(slots, text="Selecione um slot e vincule um sprite.\nA ordem corresponde ao DAT do cliente.").pack(anchor="w", pady=(0, 8))
        self.slot_tree = ttk.Treeview(slots, columns=("slot", "sprite", "coord"), show="headings", selectmode="browse")
        for key, title, width in (("slot", "Slot", 42), ("sprite", "Sprite ID", 68), ("coord", "x,y,l,px,py,pz,f", 150)):
            self.slot_tree.heading(key, text=title)
            self.slot_tree.column(key, width=width, stretch=key == "coord")
        scrollbar = ttk.Scrollbar(slots, command=self.slot_tree.yview)
        self.slot_tree.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side="right", fill="y")
        self.slot_tree.pack(fill="both", expand=True)
        self.slot_tree.bind("<<TreeviewSelect>>", self.select_slot)
        ttk.Button(slots, text="Definir ID do slot…", command=self.set_slot_id).pack(fill="x", pady=5)

    def update_title(self):
        location = str(self.project.directory) if self.project.directory else "Novo projeto"
        self.root.title(f"{'* ' if self.dirty or self.pending else ''}Backlands Asset Studio — {location}")

    def mark_dirty(self):
        self.dirty = True
        self.update_title()

    def mark_pending(self, *_):
        if not self.loading:
            self.pending = True
            self.update_exact_size()
            self.update_title()

    def update_exact_size(self):
        try:
            single_tile = self.dim_vars["width"].get() == self.dim_vars["height"].get() == 1
        except tk.TclError:
            return
        self.dim_widgets["exact_size"].configure(state="disabled" if single_tile else "normal")
        if single_tile and self.dim_vars["exact_size"].get() != 16:
            self.dim_vars["exact_size"].set(16)

    def confirm_discard(self):
        self.pixel.finish()
        if self.dirty or self.pending:
            answer = messagebox.askyesnocancel("Alterações pendentes", "Salvar as alterações antes de continuar?", parent=self.root)
            if answer is None:
                return False
            if answer:
                return self.save()
        return True

    def install_project(self, project):
        self.stop_animation()
        self.project = project
        self.thing = None
        self.group_index = self.sprite_id = self.page = 0
        self.dirty = self.pending = False
        self.undo_stack.clear()
        self.redo_stack.clear()
        self.search.set("")
        self.refresh_objects()
        self.refresh_library()
        self.select_sprite(0)
        self.update_title()
        self.remember_current_project()
        opts = project.options
        self.status.set(f"8.60 · 16×16 · {'RGBA' if opts.transparency else 'RGB'} · IDs {'32' if opts.extended else '16'} bits · {len(project.spr)} sprites")

    def remember_current_project(self):
        if self.project.directory:
            metadata = self.project.directory / self.project.otfi_name
            remember_project(metadata if metadata.is_file() else self.project.directory)

    def new(self):
        if not self.confirm_discard():
            return
        dialog = FormatDialog(self.root)
        if dialog.options:
            self.install_project(Project.new(dialog.options))

    def open(self):
        path = filedialog.askopenfilename(parent=self.root, title="Abrir projeto 16×16", filetypes=(("Projeto OTFI", "*.otfi"), ("Todos", "*.*")))
        if path:
            self.open_path(Path(path))

    def open_directory(self):
        path = filedialog.askdirectory(parent=self.root, title="Pasta com Tibia.dat e Tibia.spr")
        if path:
            self.open_path(Path(path))

    def open_path(self, path):
        if not self.confirm_discard():
            return
        path = Path(path)
        options = None
        if path.is_dir() and not list(path.glob("*.otfi")):
            dialog = FormatDialog(self.root, "Arquivos sem OTFI — confirme o formato")
            if not dialog.options:
                return
            options = dialog.options
        self.root.configure(cursor="watch")
        self.status.set(f"Carregando assets de {path}…")
        self.root.update_idletasks()
        try:
            project = Project.load(path, options=options)
        finally:
            self.root.configure(cursor="")
        self.install_project(project)

    def save(self):
        self.pixel.finish()
        if not self.apply_properties():
            return False
        if not self.project.directory:
            return self.save_as()
        self.root.configure(cursor="watch")
        self.root.update_idletasks()
        try:
            directory = self.project.save()
        finally:
            self.root.configure(cursor="")
        self.dirty = False
        self.remember_current_project()
        self.update_title()
        self.status.set(f"Salvo em {directory} · originais preservados em .backups quando substituídos")
        return True

    def save_as(self):
        self.pixel.finish()
        if not self.apply_properties():
            return False
        path = filedialog.askdirectory(parent=self.root, title="Salvar DAT + SPR + OTFI na pasta")
        if not path:
            return False
        self.project.save(Path(path))
        self.dirty = False
        self.remember_current_project()
        self.update_title()
        self.status.set(f"DAT + SPR + OTFI salvos em {path}")
        return True

    def close(self):
        if self.confirm_discard():
            self.stop_animation()
            self.root.destroy()

    def change_category(self, _event=None):
        if not self.apply_properties():
            self.category_var.set(CATEGORIES[self.category])
            return
        self.category = CATEGORIES.index(self.category_var.get())
        self.search.set("")
        self.refresh_objects()

    @staticmethod
    def thing_name(thing):
        for attr in thing.attributes:
            if attr.code == 33:
                return str(attr.values[3])
        return "Objeto %d" % thing.id

    def filter_objects(self):
        if hasattr(self, "objects"):
            self.refresh_objects(self.thing.id if self.thing else None)

    def refresh_objects(self, selected=None):
        self.objects.delete(*self.objects.get_children())
        query = self.search.get().strip().lower()
        things = self.project.dat.categories[self.category]
        visible = [t for t in things if not query or query in str(t.id) or query in self.thing_name(t).lower()]
        for thing in visible:
            self.objects.insert("", "end", iid=str(thing.id), values=(thing.id, self.thing_name(thing)))
        if visible:
            target = str(selected) if selected and any(t.id == selected for t in visible) else str(visible[0].id)
            self.objects.selection_set(target)
            self.objects.see(target)
        elif not things:
            self.thing = None
            self.pending = False
            self.clear_properties()
            self.draw_preview()

    def select_thing(self, _event=None):
        selected = self.objects.selection()
        if not selected:
            return
        id = int(selected[0])
        if self.thing and self.thing.id == id and self.thing.category == self.category:
            return
        self.pixel.finish()
        if not self.apply_properties():
            if self.thing and self.objects.exists(str(self.thing.id)):
                self.objects.selection_set(str(self.thing.id))
            return
        self.stop_animation()
        self.thing = next(t for t in self.project.dat.categories[self.category] if t.id == id)
        self.group_index = 0
        self.load_properties()

    def add_thing(self, duplicate=False):
        if not self.apply_properties():
            return
        thing = self.project.add_thing(self.category, self.thing if duplicate else None)
        self.mark_dirty()
        self.search.set("")
        self.refresh_objects(thing.id)
        self.status.set(f"{CATEGORIES[self.category]} · criado ID {thing.id}")

    def clear_properties(self):
        self.loading = True
        for key, variable in self.dim_vars.items():
            variable.set(16 if key == "exact_size" else 1)
        for enabled, value in self.flag_vars.values():
            enabled.set(False)
            value.set("")
        self.slot_tree.delete(*self.slot_tree.get_children())
        self.loading = False
        self.animation_panel.load()

    def load_properties(self):
        if not self.thing:
            self.clear_properties()
            return
        self.loading = True
        group = self.thing.groups[self.group_index]
        for key, variable in self.dim_vars.items():
            variable.set(getattr(group, key))
        self.group_type.set(group.group_type)
        self.group_var.set(self.group_index)
        self.group_combo.configure(values=tuple(range(len(self.thing.groups))))
        self.animation_meta.set(f"{group.animation_mode}, {group.loop_count}, {group.start_frame}")
        self.duration_text.set(", ".join(f"{low}:{high}" for low, high in group.durations))
        attrs = {a.code: a for a in self.thing.attributes}
        for code, (enabled, value) in self.flag_vars.items():
            enabled.set(code in attrs)
            stream = io.StringIO()
            if code in attrs:
                csv.writer(stream, lineterminator="").writerow(attrs[code].values)
            value.set(stream.getvalue())
        for key, (variable, combo) in self.selectors.items():
            count = group.frames if key == "frame" else getattr(group, key)
            combo.configure(values=tuple(range(count)))
            variable.set(min(max(0, variable.get()), count - 1))
        self.pending = False
        self.update_exact_size()
        self.loading = False
        self.animation_panel.load()
        self.refresh_slots()
        self.draw_preview()
        self.update_title()

    def apply_properties(self):
        if not self.thing or not self.pending:
            return True
        try:
            candidate = copy.deepcopy(self.thing)
            group = candidate.groups[self.group_index]
            dims = {key: variable.get() for key, variable in self.dim_vars.items()}
            if any(not 1 <= value <= 255 for value in dims.values()):
                raise ValueError("Dimensões e tamanho exato devem estar entre 1 e 255.")
            if dims["width"] * dims["height"] > 256:
                raise ValueError("Use no máximo 256 tiles por objeto.")
            group.resize(**dims)
            group.group_type = self.group_type.get()
            if group.group_type not in (0, 1):
                raise ValueError("Tipo do grupo deve ser 0 (parado) ou 1 (andando).")
            if self.project.options.frame_groups:
                validate_group_types(candidate)
            if self.project.options.frame_durations and group.frames > 1:
                meta = [int(v.strip()) for v in self.animation_meta.get().split(",")]
                if len(meta) != 3:
                    raise ValueError("Animação: informe modo, ciclos, quadro inicial.")
                group.animation_mode, group.loop_count, group.start_frame = meta
                text = self.duration_text.get().strip()
                durations = [tuple(int(v.strip()) for v in pair.split(":")) for pair in text.split(",")] if text else [(150, 150)] * group.frames
                original = self.thing.groups[self.group_index]
                previous = ", ".join(f"{low}:{high}" for low, high in original.durations)
                if group.frames != original.frames and text == previous:
                    durations = list(original.durations[:group.frames])
                    durations.extend([DEFAULT_DURATION] * (group.frames - len(durations)))
                    if meta[2] == original.start_frame and meta[2] >= group.frames:
                        group.start_frame = 0
                if len(durations) != group.frames or any(len(d) != 2 or d[0] < 0 or d[0] > d[1] for d in durations):
                    raise ValueError("Informe um par min:max válido por quadro, em milissegundos.")
                group.durations = durations
                validate_animation(group)
            attrs = {}
            for code, (enabled, variable) in self.flag_vars.items():
                if not enabled.get():
                    continue
                fields = FLAG_SPECS[code][1]
                raw = next(csv.reader([variable.get()])) if fields else []
                if len(raw) != len(fields):
                    raise ValueError(f"{FLAG_SPECS[code][0]}: informe {len(fields)} valores separados por vírgula.")
                values = tuple(value if code == 33 and index == 3 else int(value.strip(), 0) if value.strip().lower().startswith("0x") else int(value.strip()) for index, value in enumerate(raw))
                attrs[code] = Attribute(code, values)
            order = [attr.code for attr in candidate.attributes if attr.code in attrs]
            order.extend(code for code in attrs if code not in order)
            candidate.attributes = [attrs[code] for code in order]
            # Serialize the candidate alone before committing any UI edits.
            from .formats import DatFile, write_dat
            categories = [[], [], [], []]
            item = copy.deepcopy(candidate)
            item.id = 100 if candidate.category == 0 else 1
            categories[candidate.category] = [item]
            write_dat(DatFile(categories=categories), self.project.options)
        except (ValueError, OverflowError, tk.TclError) as error:
            messagebox.showerror("Propriedades inválidas", str(error), parent=self.root)
            return False
        self.thing.attributes = candidate.attributes
        self.stop_animation()
        self.thing.groups = candidate.groups
        self.pending = False
        self.mark_dirty()
        self.load_properties()
        self.status.set(f"Propriedades aplicadas ao objeto {self.thing.id}")
        return True

    def change_group(self, _event=None):
        target = self.group_var.get()
        if not self.apply_properties():
            self.group_var.set(self.group_index)
            return
        self.stop_animation()
        if not self.thing or not 0 <= target < len(self.thing.groups):
            return
        self.group_index = target
        self.load_properties()

    def enable_animation_feature(self, feature):
        if not self.apply_properties():
            return
        self.stop_animation()
        if feature == "frame_groups":
            changed = enable_frame_groups(self.project.dat, self.project.options)
        elif feature == "frame_durations":
            changed = enable_frame_durations(self.project.dat, self.project.options)
        else:
            raise ValueError("Extensão de animação desconhecida.")
        if changed:
            self.mark_dirty()
            self.load_properties()
            self.status.set("Extensão ativada. Salve para atualizar DAT e OTFI do projeto.")

    def add_group(self, duplicate=True):
        if not self.thing or not self.apply_properties():
            return
        self.stop_animation()
        self.group_index = create_group(self.thing, self.project.options, self.group_index, duplicate=duplicate)
        self.mark_dirty()
        self.load_properties()

    def remove_group(self):
        if self.thing and len(self.thing.groups) > 1 and self.apply_properties():
            if messagebox.askyesno("Remover grupo", "Remover este grupo de animação? As sprites da biblioteca serão preservadas.", parent=self.root):
                self.stop_animation()
                self.group_index = remove_group(self.thing, self.group_index)
                self.mark_dirty()
                self.load_properties()

    def edit_animation_frame(self, action):
        if not self.thing or not self.apply_properties():
            return
        self.stop_animation()
        group = self.thing.groups[self.group_index]
        frame = min(self.selectors["frame"][0].get(), group.frames - 1)
        options = {"durations": self.project.options.frame_durations}
        if action == "insert":
            selected = insert_frame(group, frame + 1, **options)
        elif action == "duplicate":
            selected = duplicate_frame(group, frame, **options)
        elif action == "remove":
            if group.frames == 1:
                return
            selected = remove_frame(group, frame, **options)
        elif action in ("up", "down"):
            destination = frame + (-1 if action == "up" else 1)
            if not 0 <= destination < group.frames:
                return
            selected = move_frame(group, frame, destination, **options)
        else:
            raise ValueError("Operação de quadro desconhecida.")
        self.selectors["frame"][0].set(selected)
        self.mark_dirty()
        self.load_properties()

    def refresh_slots(self):
        coordinates = self.slot_coordinates()
        self.slot_tree.delete(*self.slot_tree.get_children())
        if not self.thing:
            return
        g = self.thing.groups[self.group_index]
        # The view is paged by animation selection so huge objects stay responsive.
        frame = self.selectors["frame"][0].get()
        px, py, pz = (self.selectors[key][0].get() for key in ("pattern_x", "pattern_y", "pattern_z"))
        for layer in range(g.layers):
            for y in range(g.height):
                for x in range(g.width):
                    slot = g.sprite_index(x, y, layer, px, py, pz, frame)
                    self.slot_tree.insert("", "end", iid=str(slot), values=(slot, g.sprites[slot], f"{x},{y},{layer},{px},{py},{pz},{frame}"))
        if coordinates:
            try:
                slot = str(g.sprite_index(*coordinates))
                if self.slot_tree.exists(slot):
                    self.slot_tree.selection_set(slot)
            except IndexError:
                pass

    def slot_coordinates(self):
        selection = self.slot_tree.selection()
        if selection:
            return tuple(int(v) for v in self.slot_tree.item(selection[0], "values")[2].split(","))
        return None

    def select_slot(self, _event=None):
        selection = self.slot_tree.selection()
        if self.thing and selection:
            self.select_sprite(self.thing.groups[self.group_index].sprites[int(selection[0])])

    def set_slot_id(self):
        coordinates = self.slot_coordinates()
        if not self.thing or coordinates is None or not self.apply_properties():
            return
        value = simpledialog.askinteger("Sprite do slot", f"ID entre 0 e {len(self.project.spr)}", parent=self.root, minvalue=0, maxvalue=len(self.project.spr))
        if value is not None:
            self.sprite_id = value
            self.link_sprite(coordinates=coordinates)

    def link_sprite(self, _event=None, coordinates=None):
        if not self.thing:
            return
        coordinates = coordinates or self.slot_coordinates()
        if coordinates is None:
            self.status.set("Na aba Sprites / slots, selecione o slot de destino.")
            return
        sprite_id = self.sprite_id
        if not self.apply_properties():
            return
        group = self.thing.groups[self.group_index]
        try:
            index = group.sprite_index(*coordinates)
        except IndexError:
            self.status.set("O slot selecionado foi removido pela mudança de geometria.")
            return
        group.sprites[index] = sprite_id
        self.mark_dirty()
        self.draw_preview()
        self.refresh_slots()
        self.slot_tree.selection_set(str(index))

    def draw_preview(self):
        if not hasattr(self, "preview_canvas"):
            return
        self.preview_canvas.delete("all")
        if not self.thing:
            self.preview_canvas.create_text(160, 80, text="Crie ou selecione um objeto", fill="#566573")
            return
        if self.group_index >= len(self.thing.groups):
            return
        group = self.thing.groups[self.group_index]
        kwargs = {key: min(variable.get(), (group.frames if key == "frame" else getattr(group, key)) - 1) for key, (variable, _combo) in self.selectors.items()}
        image = self.project.render_thing(self.thing, group=self.group_index, **kwargs)
        if hasattr(self, "animation_panel"):
            self.animation_panel.show_frame(kwargs["frame"])
        scale = self.preview_zoom.get()
        width = max(1, self.preview_canvas.winfo_width() - 20)
        height = max(1, self.preview_canvas.winfo_height() - 20)
        scale = min(scale, max(1, width // image.width), max(1, height // image.height))
        image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST)
        background = checker(image.size)
        background.alpha_composite(image)
        self.preview_image = ImageTk.PhotoImage(background)
        self.preview_canvas.create_image(max(10, self.preview_canvas.winfo_width() // 2), max(10, self.preview_canvas.winfo_height() // 2), image=self.preview_image)
        self.refresh_slots()

    def toggle_animation(self):
        if self.playing:
            self.stop_animation()
        elif self.thing and self.apply_properties():
            self.playing = True
            self.play_button.configure(text="■ Parar")
            group = self.thing.groups[self.group_index]
            self.animation_playback = AnimationPlayback(
                group, timed=self.project.options.frame_durations,
                now_ms=int(time.monotonic() * 1000), selected_frame=self.selectors["frame"][0].get(),
            )
            self.selectors["frame"][0].set(self.animation_playback.frame)
            self.animate()

    def stop_animation(self):
        self.playing = False
        if self.animation_job:
            self.root.after_cancel(self.animation_job)
            self.animation_job = None
        if hasattr(self, "play_button"):
            self.play_button.configure(text="▶ Animar")

    def animate(self):
        if not self.playing or not self.thing:
            return
        variable = self.selectors["frame"][0]
        self.draw_preview()
        playback = self.animation_playback
        # Tk's native timer uses a signed millisecond count; split longer waits.
        delay = playback.delay()
        def next_frame():
            if self.playing and self.thing and playback is self.animation_playback:
                self.animation_job = None
                if playback.advance():
                    variable.set(playback.frame)
                    self.animate()
                else:
                    self.stop_animation()
        def wait_remaining(remaining):
            if not self.playing or playback is not self.animation_playback:
                return
            portion = min(remaining, 0x7FFFFFFF)
            callback = next_frame if remaining <= portion else lambda: wait_remaining(remaining - portion)
            self.animation_job = self.root.after(portion, callback)
        wait_remaining(delay)

    def refresh_library(self):
        self.library_canvas.delete("all")
        self.library_images.clear()
        count = len(self.project.spr)
        self.page = min(self.page, count // 32)
        self.page_text.set(f"{self.page + 1}/{count // 32 + 1} · {count} sprites")
        for n in range(32):
            id = self.page * 32 + n
            if id > count:
                break
            x, y = (n % 8) * 58 + 3, (n // 8) * 46 + 1
            image = checker((32, 32), 4)
            image.alpha_composite(Image.frombytes("RGBA", (16, 16), self.project.spr.get(id)).resize((32, 32), Image.Resampling.NEAREST))
            photo = ImageTk.PhotoImage(image)
            self.library_images.append(photo)
            if id == self.sprite_id:
                self.library_canvas.create_rectangle(x, y, x + 37, y + 44, fill="#c0e8d0", outline="#238353", width=2)
            self.library_canvas.create_image(x + 3, y + 1, anchor="nw", image=photo)
            self.library_canvas.create_text(x + 19, y + 39, text=str(id), font=("Segoe UI", 8))

    def change_page(self, amount):
        self.page = min(max(0, self.page + amount), len(self.project.spr) // 32)
        self.refresh_library()

    def click_library(self, event):
        col, row = (event.x - 3) // 58, (event.y - 1) // 46
        if not (0 <= col < 8 and 0 <= row < 4):
            return
        id = self.page * 32 + row * 8 + col
        if id <= len(self.project.spr):
            self.select_sprite(id)

    def select_sprite(self, id):
        self.pixel.finish()
        self.sprite_id = id
        self.selected_text.set(f"Sprite {id}" + (" (transparente)" if id == 0 else ""))
        self.pixel.load(self.project.spr.get(id), enabled=id != 0)
        self.refresh_library()

    def goto_sprite(self):
        value = simpledialog.askinteger("Ir ao sprite", "ID do sprite", minvalue=0, maxvalue=len(self.project.spr), parent=self.root)
        if value is not None:
            self.page = value // 32
            self.select_sprite(value)

    def add_sprite(self):
        self.pixel.finish()
        self.project._check_capacity(1)
        id = self.project.spr.append(bytes(1024))
        self.page = id // 32
        self.select_sprite(id)
        self.mark_dirty()
        self.center_notebook.select(self.pixel)

    def import_sprites(self):
        self.pixel.finish()
        path = filedialog.askopenfilename(parent=self.root, title="Importar PNG / folha em células 16×16", filetypes=(("PNG", "*.png"),))
        if path:
            ids = self.project.import_sprite_sheet(Path(path))
            self.page = ids[0] // 32
            self.select_sprite(ids[0])
            self.mark_dirty()
            self.status.set(f"Importadas {len(ids)} sprites: IDs {ids[0]} a {ids[-1]}")

    def replace_sprite(self):
        self.pixel.finish()
        if self.sprite_id == 0:
            raise ValueError("O sprite 0 é a transparência. Crie ou selecione outro sprite.")
        path = filedialog.askopenfilename(parent=self.root, title="Substituir sprite por PNG de 16×16", filetypes=(("PNG", "*.png"),))
        if path:
            before = self.project.spr.get(self.sprite_id)
            self.project.replace_sprite(Path(path), self.sprite_id)
            self.record_pixels(before, self.project.spr.get(self.sprite_id))
            self.select_sprite(self.sprite_id)
            self.draw_preview()

    def export_sprite(self):
        self.pixel.finish()
        path = filedialog.asksaveasfilename(parent=self.root, title="Exportar sprite", initialfile=f"sprite-{self.sprite_id}.png", defaultextension=".png", filetypes=(("PNG", "*.png"),))
        if path:
            Image.frombytes("RGBA", (16, 16), self.project.spr.get(self.sprite_id)).save(path)
            self.status.set(f"PNG exportado: {path}")

    def pixel_changed(self, before, after):
        if not self.project.options.transparency and any(after[i] not in (0, 255) for i in range(3, len(after), 4)):
            raise ValueError("Este projeto usa RGB: o alpha deve ser 0 ou 255. Crie um projeto com alpha parcial para usar outros valores.")
        self.project.spr.set(self.sprite_id, after)
        self.record_pixels(before, after)
        self.refresh_library()
        self.draw_preview()

    def record_pixels(self, before, after):
        self.undo_stack.append((self.sprite_id, before, after))
        del self.undo_stack[:-200]
        self.redo_stack.clear()
        self.mark_dirty()

    def undo(self):
        self.pixel.finish()
        if self.undo_stack:
            id, before, after = self.undo_stack.pop()
            self.project.spr.set(id, before)
            self.redo_stack.append((id, before, after))
            self.page = id // 32
            self.select_sprite(id)
            self.mark_dirty()
            self.draw_preview()

    def redo(self):
        self.pixel.finish()
        if self.redo_stack:
            id, before, after = self.redo_stack.pop()
            self.project.spr.set(id, after)
            self.undo_stack.append((id, before, after))
            self.page = id // 32
            self.select_sprite(id)
            self.mark_dirty()
            self.draw_preview()

    def export_preview(self):
        if not self.thing or not self.apply_properties():
            return
        self.pixel.finish()
        path = filedialog.asksaveasfilename(parent=self.root, title="Exportar prévia na resolução original", initialfile=f"objeto-{self.thing.id}.png", defaultextension=".png", filetypes=(("PNG", "*.png"),))
        if path:
            self.project.render_thing(self.thing, group=self.group_index, **{key: variable.get() for key, (variable, _) in self.selectors.items()}).save(path)
            self.status.set(f"Prévia exportada: {path}")

    def export_thing_sheet(self):
        if not self.thing or not self.apply_properties():
            return
        self.pixel.finish()
        path = filedialog.asksaveasfilename(parent=self.root, title="Exportar todos os quadros / padrões / camadas deste grupo", initialfile=f"objeto-{self.thing.id}-grupo-{self.group_index}.png", defaultextension=".png", filetypes=(("PNG", "*.png"),))
        if path:
            self.project.export_thing_sheet(self.thing, Path(path), group=self.group_index)
            self.status.set(f"Folha exportada: {path}")

    def import_thing_sheet(self):
        if not self.thing or not self.apply_properties():
            return
        self.pixel.finish()
        path = filedialog.askopenfilename(parent=self.root, title="Importar folha com a geometria do grupo atual", filetypes=(("PNG", "*.png"),))
        if path:
            self.project.import_thing_sheet(self.thing, Path(path), group=self.group_index)
            self.mark_dirty()
            self.refresh_library()
            self.draw_preview()

    def about(self):
        messagebox.showinfo("Backlands Asset Studio", "Editor desktop de DAT / SPR 8.60 para Backlands.\nSprites nativos de 16×16; sem redimensionamento implícito.\n\nInspirado no fluxo do ObjectBuilder de punkice3407.\nExtensões: IDs 32 bits, RGBA, durações e grupos via OTFI.\n\nO NexaMap deve usar o build NEXAMAP_SPRITE_PIXELS=16.\nOTB e XML do servidor são mantidos separadamente.\n\nConsulte object-editor/README.md para o formato das folhas.", parent=self.root)


def main(path: Path | None = None):
    root = tk.Tk()
    Editor(root, startup_project(path))
    root.mainloop()
