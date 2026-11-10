"""Pixel canvas and preview helpers for the native 16px editor."""
from __future__ import annotations

import tkinter as tk
from tkinter import colorchooser, ttk

from PIL import Image, ImageDraw, ImageTk


def checker(size: tuple[int, int], cell: int = 8) -> Image.Image:
    image = Image.new("RGBA", size, "#d3d9de")
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill="#edf0f3")
    return image


class PixelEditor(ttk.Frame):
    """Edits one 16x16 RGBA sprite; one callback/undo unit per stroke."""

    def __init__(self, parent, on_change):
        super().__init__(parent, padding=10)
        self.on_change = on_change
        self.pixels = bytes(16 * 16 * 4)
        self.before: bytes | None = None
        self.tool = tk.StringVar(value="Lápis")
        self.color = (81, 151, 70, 255)
        self.alpha = tk.IntVar(value=255)
        self.grid = tk.BooleanVar(value=True)
        self.scale = tk.IntVar(value=16)
        self.image_ref = None
        self.last = None
        self.enabled = False
        bar = ttk.Frame(self)
        bar.pack(fill="x", pady=(0, 8))
        for tool in ("Lápis", "Borracha", "Preencher", "Conta-gotas"):
            ttk.Radiobutton(bar, text=tool, variable=self.tool, value=tool).pack(side="left", padx=3)
        colors = ttk.Frame(self)
        colors.pack(fill="x", pady=(0, 8))
        ttk.Button(colors, text="Escolher cor", command=self.choose_color).pack(side="left")
        self.swatch = tk.Label(colors, width=3, background="#519746")
        self.swatch.pack(side="left", padx=6)
        ttk.Label(colors, text="Alpha").pack(side="left", padx=(8, 2))
        ttk.Spinbox(colors, from_=0, to=255, width=5, textvariable=self.alpha).pack(side="left")
        ttk.Checkbutton(colors, text="Grade", variable=self.grid, command=self.draw).pack(side="left", padx=10)
        ttk.Label(colors, text="Zoom").pack(side="left")
        zoom = ttk.Combobox(colors, textvariable=self.scale, values=(12, 16, 20, 22, 28, 32), width=4, state="readonly")
        zoom.pack(side="left", padx=4)
        zoom.bind("<<ComboboxSelected>>", lambda _e: self.draw())
        host = ttk.Frame(self)
        host.pack(fill="both", expand=True)
        host.rowconfigure(0, weight=1)
        host.columnconfigure(0, weight=1)
        self.canvas = tk.Canvas(host, background="#e8edf1", highlightthickness=0, cursor="crosshair")
        self.canvas.grid(row=0, column=0, sticky="nsew")
        horizontal = ttk.Scrollbar(host, orient="horizontal", command=self.canvas.xview)
        vertical = ttk.Scrollbar(host, orient="vertical", command=self.canvas.yview)
        horizontal.grid(row=1, column=0, sticky="ew")
        vertical.grid(row=0, column=1, sticky="ns")
        self.canvas.configure(xscrollcommand=horizontal.set, yscrollcommand=vertical.set)
        self.canvas.bind("<Configure>", lambda _e: self.draw())
        self.canvas.bind("<Button-1>", self.start)
        self.canvas.bind("<B1-Motion>", self.paint)
        self.canvas.bind("<ButtonRelease-1>", self.finish)
        self.canvas.bind("<Button-3>", self.pick)
        ttk.Label(self, text="Botão direito: capturar cor · Ctrl+Z / Ctrl+Y: desfazer / refazer pixels").pack(pady=(8, 0))

    def choose_color(self):
        result = colorchooser.askcolor(self.color[:3], parent=self)
        if result[0]:
            self.color = tuple(round(v) for v in result[0]) + (255,)
            self.swatch.configure(background=result[1])

    def load(self, rgba: bytes, enabled: bool = True):
        self.finish()
        self.pixels = bytes(rgba)
        self.enabled = enabled
        self.draw()

    def draw(self):
        scale = self.scale.get()
        size = 16 * scale
        self.origin = (max(8, (self.canvas.winfo_width() - size) // 2), 8)
        image = checker((size, size), scale)
        image.alpha_composite(Image.frombytes("RGBA", (16, 16), self.pixels).resize((size, size), Image.Resampling.NEAREST))
        if self.grid.get():
            draw = ImageDraw.Draw(image)
            for p in range(0, size, scale):
                draw.line((p, 0, p, size), fill=(80, 90, 100, 100))
                draw.line((0, p, size, p), fill=(80, 90, 100, 100))
        self.image_ref = ImageTk.PhotoImage(image)
        self.canvas.delete("all")
        self.canvas.create_image(*self.origin, image=self.image_ref, anchor="nw")
        self.canvas.configure(scrollregion=(0, 0, size + 16, size + 16))

    def position(self, event):
        x = int((self.canvas.canvasx(event.x) - self.origin[0]) // self.scale.get())
        y = int((self.canvas.canvasy(event.y) - self.origin[1]) // self.scale.get())
        return (x, y) if 0 <= x < 16 and 0 <= y < 16 else None

    def pick(self, event):
        pos = self.position(event)
        if pos:
            i = (pos[1] * 16 + pos[0]) * 4
            self.color = tuple(self.pixels[i:i + 4])
            self.alpha.set(self.color[3])
            self.swatch.configure(background="#%02x%02x%02x" % self.color[:3])

    def start(self, event):
        if not self.enabled:
            return
        if self.tool.get() == "Conta-gotas":
            self.pick(event)
            return
        self.before = self.pixels
        self.last = None
        self.paint(event)

    def paint(self, event):
        pos = self.position(event)
        if pos is None or self.before is None:
            return
        try:
            alpha = max(0, min(255, self.alpha.get()))
        except tk.TclError:
            return
        rgba = bytes(self.color[:3] + (alpha,)) if self.tool.get() != "Borracha" else bytes(4)
        pixels = bytearray(self.pixels)
        if self.tool.get() == "Preencher":
            i = (pos[1] * 16 + pos[0]) * 4
            target = bytes(pixels[i:i + 4])
            pending, seen = [pos], set()
            while pending:
                x, y = pending.pop()
                if (x, y) in seen or not (0 <= x < 16 and 0 <= y < 16):
                    continue
                seen.add((x, y))
                i = (y * 16 + x) * 4
                if pixels[i:i + 4] == target:
                    pixels[i:i + 4] = rgba
                    pending.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
        else:
            x, y = self.last or pos
            dx, dy = pos[0] - x, pos[1] - y
            steps = max(abs(dx), abs(dy), 1)
            for t in range(steps + 1):
                px, py = round(x + dx * t / steps), round(y + dy * t / steps)
                i = (py * 16 + px) * 4
                pixels[i:i + 4] = rgba
        self.last = pos
        self.pixels = bytes(pixels)
        self.draw()

    def finish(self, _event=None):
        if self.before is not None:
            before, self.before = self.before, None
            if before != self.pixels:
                try:
                    self.on_change(before, self.pixels)
                except ValueError as error:
                    self.pixels = before
                    self.draw()
                    from tkinter import messagebox
                    messagebox.showerror("Sprite inválido", str(error), parent=self)
        self.last = None
