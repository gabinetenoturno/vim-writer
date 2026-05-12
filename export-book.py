#!/usr/bin/env python3
"""
export-book.py — Exporta Rascunho/ de um projeto para PDF polido.
Uso: python3 export-book.py <caminho-do-projeto> [nome-saida.pdf]

Convencoes de nomenclatura em Rascunho/:
  Pre-conteudo/ (dir sem numero inicial):
    Xa - Titulo.md  => pagina impar (cleardoublepage)
    Xb - Titulo.md  => pagina par   (clearpage), verso do Xa
    X  - Titulo.md  => pagina impar (cleardoublepage)

  N - Nome do Conto/ (dir com numero inicial):
    Todos os arquivos .md concatenados em ordem numerica.
    Primeira cena comeca em pagina impar; demais separadas por linha em branco.
"""

import os
import re
import sys
import subprocess
import tempfile
from pathlib import Path


def sort_key(name: str):
    m = re.match(r'^(\d+)', name)
    return (int(m.group(1)) if m else 0, name)


def collect_files(rascunho: Path):
    """
    Retorna lista ordenada de (Path, break_before):
      'odd'  -> cleardoublepage (proxima pagina impar)
      'even' -> clearpage (proxima pagina par)
      'cont' -> linha em branco (continuacao dentro do mesmo conto)
    """
    subdirs = sorted(rascunho.iterdir(), key=lambda d: sort_key(d.name))
    subdirs = [d for d in subdirs if d.is_dir()]

    pre_dirs   = [d for d in subdirs if not re.match(r'^\d', d.name)]
    story_dirs = [d for d in subdirs if re.match(r'^\d', d.name)]

    result = []

    for d in pre_dirs:
        md_files = sorted(
            [f for f in d.iterdir() if f.suffix == '.md'],
            key=lambda f: sort_key(f.name),
        )
        for f in md_files:
            m = re.match(r'^\d+(a|b)?', f.stem)
            suffix = m.group(1) if m else None
            result.append((f, 'even' if suffix == 'b' else 'odd'))

    for d in story_dirs:
        md_files = sorted(
            [f for f in d.iterdir() if f.suffix == '.md'],
            key=lambda f: sort_key(f.name),
        )
        for i, f in enumerate(md_files):
            result.append((f, 'odd' if i == 0 else 'cont'))

    return result


def build_combined(files) -> str:
    parts = []
    for i, (filepath, break_before) in enumerate(files):
        content = filepath.read_text(encoding='utf-8').strip()

        if i > 0:
            if break_before == 'odd':
                parts.append('\n\n\\cleardoublepage\n\n')
            elif break_before == 'even':
                parts.append('\n\n\\clearpage\n\n')
            else:
                parts.append('\n\n')

        parts.append(content)

    return ''.join(parts)


def export(project_dir: str, output_name: str = None):
    project  = Path(project_dir).resolve()
    rascunho = project / 'Rascunho'

    if not rascunho.exists():
        print(f"Erro: diretório Rascunho/ não encontrado em {project}", file=sys.stderr)
        sys.exit(1)

    export_dir = Path.home() / 'WriteDir' / 'exportado'
    export_dir.mkdir(parents=True, exist_ok=True)

    if not output_name:
        output_name = project.name + '.pdf'
    output_path = export_dir / output_name

    files    = collect_files(rascunho)
    combined = build_combined(files)

    with tempfile.NamedTemporaryFile(
        suffix='.md', mode='w', encoding='utf-8', delete=False
    ) as tmp:
        tmp.write(combined)
        tmp_path = tmp.name

    try:
        cmd = [
            'pandoc', tmp_path,
            '-o', str(output_path),
            '--pdf-engine=xelatex',
            '--from=markdown-yaml_metadata_block+raw_tex',
            '-V', 'lang=pt-BR',
            '-V', 'fontsize=12pt',
            '-V', 'documentclass=book',
            '-V', 'papersize=a5',
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"Exportado: {output_path}")
        else:
            print(result.stderr, file=sys.stderr)
            sys.exit(1)
    finally:
        os.unlink(tmp_path)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Uso: {sys.argv[0]} <projeto> [saida.pdf]")
        sys.exit(1)
    export(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
