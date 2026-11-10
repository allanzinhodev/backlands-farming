#!/usr/bin/env python3
"""Launch Backlands Asset Studio, or validate a DAT/SPR/OTFI project."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

# Also support `python -I main.py` without trusting the working directory.
sys.path.insert(0, str(Path(__file__).resolve().parent))


def main() -> int:
    parser = argparse.ArgumentParser(description="Editor DAT/SPR 8.60 com sprites nativos de 16×16.")
    parser.add_argument("project", nargs="?", type=Path, help="Pasta de assets ou arquivo .otfi")
    parser.add_argument("--check", action="store_true", help="Valida o projeto sem abrir a interface")
    args = parser.parse_args()
    try:
        if args.check:
            if args.project is None:
                parser.error("--check exige uma pasta ou arquivo .otfi")
            from backlands_editor.project import Project
            project = Project.load(args.project)
            print(f"OK: 8.60 / 16x16 / {len(project.spr)} sprites")
            for name, things in zip(("Itens", "Criaturas", "Efeitos", "Projeteis"), project.dat.categories):
                print(f"{name}: {len(things)}")
        else:
            from backlands_editor.gui import main as gui_main
            gui_main(args.project)
    except ImportError as error:
        print(f"Dependencia indisponivel: {error}\nInstale: python -m pip install -r object-editor/requirements.txt", file=sys.stderr)
        return 1
    except (OSError, ValueError) as error:
        print(f"Erro: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
