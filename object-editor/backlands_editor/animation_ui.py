"""Dedicated animation workspace, sharing the editor's pending property state."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from .animation import DEFAULT_DURATION, GROUP_NAMES


class AnimationPanel(ttk.Frame):
    def __init__(self, parent, editor):
        super().__init__(parent, padding=10)
        self.editor = editor
        self.loading = False
        self.frame_index = 0
        canvas = tk.Canvas(self, highlightthickness=0, width=500, height=320)
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)
        content = ttk.Frame(canvas)
        window = canvas.create_window((0, 0), window=content, anchor="nw")
        content.bind("<Configure>", lambda _event: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", lambda event: canvas.itemconfigure(window, width=event.width))
        self.canvas = canvas
        self.options_text = tk.StringVar()
        ttk.Label(content, textvariable=self.options_text).pack(anchor="w")
        options = ttk.Frame(content)
        options.pack(fill="x", pady=(5, 9))
        self.enable_groups = ttk.Button(options, text="Ativar grupos de criaturas", command=lambda: editor.enable_animation_feature("frame_groups"))
        self.enable_groups.pack(side="left", padx=(0, 5))
        self.enable_durations = ttk.Button(options, text="Ativar duração por quadro", command=lambda: editor.enable_animation_feature("frame_durations"))
        self.enable_durations.pack(side="left")

        groups = ttk.LabelFrame(content, text="Frame groups", padding=6)
        groups.pack(fill="x")
        self.groups = ttk.Treeview(groups, columns=("type", "frames", "shape"), show="headings", height=2, selectmode="browse")
        for key, label, width in (("type", "Tipo", 165), ("frames", "Quadros", 65), ("shape", "Tiles / camadas / padrões", 180)):
            self.groups.heading(key, text=label)
            self.groups.column(key, width=width, stretch=True)
        self.groups.pack(fill="x")
        self.groups.bind("<<TreeviewSelect>>", self.select_group)
        actions = ttk.Frame(groups)
        actions.pack(fill="x", pady=(5, 0))
        self.new_group = ttk.Button(actions, text="+ Grupo vazio", command=lambda: editor.add_group(False))
        self.new_group.pack(side="left")
        self.copy_group = ttk.Button(actions, text="Duplicar grupo", command=lambda: editor.add_group(True))
        self.copy_group.pack(side="left", padx=4)
        self.delete_group = ttk.Button(actions, text="Remover grupo", command=editor.remove_group)
        self.delete_group.pack(side="left")
        ttk.Label(actions, text="Tipo:").pack(side="left", padx=(12, 3))
        self.type_var = tk.StringVar()
        self.type_combo = ttk.Combobox(actions, textvariable=self.type_var, values=tuple(f"{key} · {value}" for key, value in GROUP_NAMES.items()), state="readonly", width=18)
        self.type_combo.pack(side="left")
        self.type_combo.bind("<<ComboboxSelected>>", self.change_type)

        frames = ttk.LabelFrame(content, text="Quadros do grupo selecionado", padding=6)
        frames.pack(fill="both", expand=True, pady=(9, 0))
        table = ttk.Frame(frames)
        table.pack(fill="both", expand=True)
        self.frames = ttk.Treeview(table, columns=("frame", "minimum", "maximum", "slots"), show="headings", height=6, selectmode="browse")
        for key, label, width in (("frame", "Quadro", 55), ("minimum", "Mín. (ms)", 85), ("maximum", "Máx. (ms)", 85), ("slots", "Slots de sprites", 105)):
            self.frames.heading(key, text=label)
            self.frames.column(key, width=width, stretch=True)
        scroll = ttk.Scrollbar(table, command=self.frames.yview)
        self.frames.configure(yscrollcommand=scroll.set)
        scroll.pack(side="right", fill="y")
        self.frames.pack(side="left", fill="both", expand=True)
        self.frames.bind("<<TreeviewSelect>>", self.select_frame)
        actions = ttk.Frame(frames)
        actions.pack(fill="x", pady=5)
        self.frame_buttons = []
        for text, action in (("+ Vazio", "insert"), ("Duplicar", "duplicate"), ("Remover", "remove"), ("↑", "up"), ("↓", "down")):
            button = ttk.Button(actions, text=text, command=lambda key=action: editor.edit_animation_frame(key))
            button.pack(side="left", padx=(0, 4))
            self.frame_buttons.append(button)
        duration = ttk.Frame(frames)
        duration.pack(fill="x", pady=4)
        self.minimum = tk.StringVar(value="150")
        self.maximum = tk.StringVar(value="150")
        self.duration_entries = []
        for label, variable in (("Mínimo (ms)", self.minimum), ("Máximo (ms)", self.maximum)):
            ttk.Label(duration, text=label).pack(side="left", padx=(0, 4))
            entry = ttk.Entry(duration, textvariable=variable, width=10)
            entry.pack(side="left", padx=(0, 12))
            self.duration_entries.append(entry)
            variable.trace_add("write", self.change_duration)

        metadata = ttk.Frame(content)
        metadata.pack(fill="x", pady=(9, 5))
        ttk.Label(metadata, text="Modo").grid(row=0, column=0, sticky="w")
        self.mode = tk.StringVar(value="0 · Assíncrono")
        self.mode_combo = ttk.Combobox(metadata, textvariable=self.mode, values=("0 · Assíncrono", "1 · Síncrono"), width=17, state="readonly")
        self.mode_combo.grid(row=1, column=0, sticky="w", padx=(0, 10))
        self.mode.trace_add("write", self.change_metadata)
        self.loops, self.start = tk.StringVar(value="0"), tk.StringVar(value="0")
        self.metadata_entries = []
        for col, label, variable in ((1, "Ciclos", self.loops), (2, "Quadro inicial", self.start)):
            ttk.Label(metadata, text=label).grid(row=0, column=col, sticky="w")
            entry = ttk.Entry(metadata, textvariable=variable, width=12)
            entry.grid(row=1, column=col, sticky="w", padx=(0, 10))
            variable.trace_add("write", self.change_metadata)
            self.metadata_entries.append(entry)
        ttk.Label(content, text="Ciclos: 0 = contínuo; negativo = ida e volta. Inicial: -1 = aleatório.\nDurações e grupos são gravados no DAT e declarados no OTFI.\nSprites de quadros removidos permanecem na biblioteca.", wraplength=600).pack(anchor="w", pady=4)
        actions = ttk.Frame(content)
        actions.pack(fill="x")
        ttk.Button(actions, text="Aplicar animação", command=editor.apply_properties).pack(side="left")
        ttk.Button(actions, text="▶ / ■ Prévia", command=editor.toggle_animation).pack(side="left", padx=5)
        def scroll_workspace(event):
            if event.delta:
                canvas.yview_scroll(-1 if event.delta > 0 else 1, "units")
            return "break"
        def bind_scroll(widget):
            if widget not in (self.frames, self.groups):
                widget.bind("<MouseWheel>", scroll_workspace, add="+")
            for child in widget.winfo_children():
                bind_scroll(child)
        canvas.bind("<MouseWheel>", scroll_workspace)
        bind_scroll(content)

    def load(self):
        editor = self.editor
        self.loading = True
        try:
            self.groups.delete(*self.groups.get_children())
            self.frames.delete(*self.frames.get_children())
            options = editor.project.options
            self.options_text.set(f"Grupos: {'ativos' if options.frame_groups else 'desativados'}   ·   Duração por quadro: {'ativa' if options.frame_durations else 'desativada'}")
            self.enable_groups.configure(state="disabled" if options.frame_groups else "normal")
            self.enable_durations.configure(state="disabled" if options.frame_durations else "normal")
            thing = editor.thing
            available = thing is not None
            can_group = bool(thing and thing.category == 1 and options.frame_groups)
            for button in (self.new_group, self.copy_group):
                button.configure(state="normal" if can_group and len(thing.groups) < 2 else "disabled")
            self.delete_group.configure(state="normal" if can_group and len(thing.groups) > 1 else "disabled")
            self.type_combo.configure(state="readonly" if can_group else "disabled")
            editable = bool(available and options.frame_durations and thing.groups[editor.group_index].frames > 1)
            self.mode_combo.configure(state="readonly" if editable else "disabled")
            for widget in self.duration_entries + self.metadata_entries:
                widget.configure(state="normal" if editable else "disabled")
            for button in self.frame_buttons:
                button.configure(state="normal" if available else "disabled")
            if not thing:
                return
            for index, group in enumerate(thing.groups):
                name = GROUP_NAMES.get(group.group_type, f"Tipo {group.group_type}")
                self.groups.insert("", "end", iid=str(index), values=(f"{group.group_type} · {name}", group.frames, f"{group.width}×{group.height} / {group.layers} / {group.pattern_x}×{group.pattern_y}×{group.pattern_z}"))
            group = thing.groups[editor.group_index]
            self.groups.selection_set(str(editor.group_index))
            self.type_var.set(f"{group.group_type} · {GROUP_NAMES.get(group.group_type, 'Desconhecido')}")
            self.mode.set(("0 · Assíncrono", "1 · Síncrono")[group.animation_mode] if group.animation_mode in (0, 1) else str(group.animation_mode))
            self.loops.set(str(group.loop_count))
            self.start.set(str(group.start_frame))
            block = len(group.sprites) // group.frames
            for index in range(group.frames):
                low, high = group.durations[index] if group.durations else DEFAULT_DURATION
                self.frames.insert("", "end", iid=str(index), values=(index, low if options.frame_durations else "—", high if options.frame_durations else "—", block))
            self.show_frame(min(editor.selectors["frame"][0].get(), group.frames - 1))
        finally:
            self.loading = False

    def show_frame(self, index):
        if not self.editor.thing or not self.frames.exists(str(index)):
            return
        loading = self.loading
        self.loading = True
        try:
            self.frame_index = index
            selected = self.frames.selection()
            if selected != (str(index),):
                self.frames.selection_set(str(index))
                self.frames.see(str(index))
            pairs = self.editor.duration_text.get().split(",")
            pair = pairs[index].strip().split(":") if index < len(pairs) and pairs[index].strip() else list(map(str, DEFAULT_DURATION))
            self.minimum.set(pair[0] if pair else "")
            self.maximum.set(pair[1] if len(pair) > 1 else "")
        finally:
            self.loading = loading

    def select_group(self, _event=None):
        selected = self.groups.selection()
        if self.loading or not selected or int(selected[0]) == self.editor.group_index:
            return
        self.editor.group_var.set(int(selected[0]))
        self.editor.change_group()
        if self.editor.group_index != int(selected[0]):
            self.groups.selection_set(str(self.editor.group_index))

    def select_frame(self, _event=None):
        selected = self.frames.selection()
        if self.loading or not selected:
            return
        index = int(selected[0])
        if index == self.editor.selectors["frame"][0].get() and index == self.frame_index:
            return
        self.editor.stop_animation()
        self.editor.selectors["frame"][0].set(index)
        self.show_frame(index)
        self.editor.draw_preview()

    def change_type(self, _event=None):
        if not self.loading:
            self.editor.stop_animation()
            self.editor.group_type.set(self.type_combo.current())

    def change_metadata(self, *_):
        if not self.loading:
            self.editor.stop_animation()
            self.editor.animation_meta.set(f"{self.mode_combo.current()}, {self.loops.get()}, {self.start.get()}")

    def change_duration(self, *_):
        if self.loading or not self.editor.thing:
            return
        self.editor.stop_animation()
        group = self.editor.thing.groups[self.editor.group_index]
        text = self.editor.duration_text.get().strip()
        pairs = [pair.strip() for pair in text.split(",")] if text else [f"{low}:{high}" for low, high in [DEFAULT_DURATION] * group.frames]
        pairs[self.frame_index] = f"{self.minimum.get()}:{self.maximum.get()}"
        self.editor.duration_text.set(", ".join(pairs))
        if self.frames.exists(str(self.frame_index)):
            self.frames.set(str(self.frame_index), "minimum", self.minimum.get())
            self.frames.set(str(self.frame_index), "maximum", self.maximum.get())
