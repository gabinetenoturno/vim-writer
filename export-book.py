#!/usr/bin/env python3
"""
export-book.py — Exporta Rascunho/ de um projeto para PDF polido.
Uso: python3 export-book.py <caminho-do-projeto> [nome-saida.pdf]

Convencoes de nomenclatura em Rascunho/:
  Pre-conteudo/ (dir sem numero inicial):
    Xa - Titulo.md  => pagina impar; se for o primeiro arquivo, vira folha de rosto
    Xb - Titulo.md  => pagina par (clearpage), verso do Xa
    X  - Titulo.md  => pagina impar (cleardoublepage)

  N - Nome do Conto/ (dir com numero inicial):
    Todos os arquivos .md concatenados em ordem numerica.
    Primeira cena comeca em pagina impar; demais separadas por linha em branco.

Design:
  - Pagina 16x23 cm (padrao brasileiro de ficcao)
  - Sem cabecalho em nenhuma pagina
  - Pre-textual sem numeracao de pagina
  - Conteudo principal: numero de pagina no rodape, sem cabecalho
  - Folha de rosto: todo o conteudo centralizado vertical e horizontalmente
"""

import os
import re
import sys
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path


def sort_key(name: str):
    m = re.match(r'^(\d+)', name)
    return (int(m.group(1)) if m else 0, name)


def collect_files(rascunho: Path):
    """
    Retorna lista ordenada de (Path, break_before, is_pretextual, is_title_page).
      break_before: 'odd' | 'even' | 'cont'
      is_pretextual: True para arquivos do pre-conteudo
      is_title_page: True apenas para o primeiro arquivo 'a' do pre-conteudo
    """
    subdirs = sorted(rascunho.iterdir(), key=lambda d: sort_key(d.name))
    subdirs = [d for d in subdirs if d.is_dir()]

    pre_dirs   = [d for d in subdirs if not re.match(r'^\d', d.name)]
    story_dirs = [d for d in subdirs if re.match(r'^\d', d.name)]

    result = []
    first_file = True

    for d in pre_dirs:
        md_files = sorted(
            [f for f in d.iterdir() if f.suffix == '.md'],
            key=lambda f: sort_key(f.name),
        )
        for f in md_files:
            m = re.match(r'^\d+(a|b)?', f.stem)
            suffix = m.group(1) if m else None
            break_type = 'even' if suffix == 'b' else 'odd'
            is_title = first_file and suffix == 'a'
            result.append((f, break_type, True, is_title))
            first_file = False

    for d in story_dirs:
        md_files = sorted(
            [f for f in d.iterdir() if f.suffix == '.md'],
            key=lambda f: sort_key(f.name),
        )
        for i, f in enumerate(md_files):
            result.append((f, 'odd' if i == 0 else 'cont', False, False))

    return result


def md_inline_to_latex(text: str) -> str:
    text = re.sub(r'\*\*(.+?)\*\*', r'\\textbf{\1}', text)
    text = re.sub(r'\*(.+?)\*',     r'\\textit{\1}', text)
    return text


def format_title_page(content: str, timestamp: str) -> str:
    """Converte a folha de rosto para LaTeX centralizado vertical e horizontalmente."""
    sizes = ['\\Huge', '\\huge', '\\LARGE', '\\Large', '\\large', '\\normalsize']
    lines = ['\\begin{titlepage}', '\\null', '\\vfill', '\\centering']

    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            lines.append('\\vspace{0.8em}')
            continue
        m = re.match(r'^(#{1,6})\s+(.+)', line)
        if m:
            level  = len(m.group(1))
            text   = md_inline_to_latex(m.group(2).strip())
            size   = sizes[min(level - 1, 5)]
            lines.append(f'{{{size} {text}\\par}}')
        else:
            text = md_inline_to_latex(line)
            lines.append(f'{{\\normalsize {text}\\par}}')

    lines += [
        '\\vfill',
        f'{{\\small\\centering {timestamp}\\par}}',
        '\\end{titlepage}',
    ]
    return '\n'.join(lines)


def build_combined(files) -> str:
    # Inicia sem numeracao e sem cabecalho (pre-textual)
    parts = ['\\pagestyle{empty}\n\n']
    prev_pretextual = True
    timestamp = datetime.now().strftime('%d/%m/%Y - %H:%M')

    for i, (filepath, break_before, is_pretextual, is_title) in enumerate(files):
        content = filepath.read_text(encoding='utf-8').strip()

        # Transicao pre-textual -> conteudo principal
        if prev_pretextual and not is_pretextual:
            # plain: numero de pagina no rodape, sem cabecalho
            parts.append('\n\n\\cleardoublepage\n\\pagestyle{plain}\n\\pagenumbering{arabic}\n\n')
        prev_pretextual = is_pretextual

        # Quebra de pagina (nao antes do primeiro arquivo)
        if i > 0:
            if break_before == 'odd':
                parts.append('\n\n\\cleardoublepage\n\n')
            elif break_before == 'even':
                parts.append('\n\n\\clearpage\n\n')
            else:
                parts.append('\n\n')

        if is_title:
            parts.append(format_title_page(content, timestamp))
        else:
            # Primeiro paragrafo de cada conto: sem recuo
            if not is_pretextual and break_before == 'odd' and not content.startswith('#'):
                content = '\\noindent ' + content
            parts.append(content)

    return ''.join(parts)


def export(project_dir: str, output_name: str = None):
    project  = Path(project_dir).resolve()
    rascunho = project / 'Rascunho'

    if not rascunho.exists():
        print(f"Erro: diretorio Rascunho/ nao encontrado em {project}", file=sys.stderr)
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

    latex_header = (
        # Fonte principal: Whitman (regular, italic, bold)
        '\\usepackage{fontspec}\n'
        '\\setmainfont[\n'
        '  Path=/usr/local/share/fonts/w/,\n'
        '  UprightFont=Whitman_RomanOsF,\n'
        '  ItalicFont=Whitman_ItalicOsF,\n'
        '  BoldFont=Whitman_BoldOsF,\n'
        '  BoldItalicFont=Whitman_ItalicOsF,\n'
        '  Extension=.ttf,\n'
        ']{Whitman}\n'
        # Tamanho do corpo: 16pt (baselineskip 1.3x)
        '\\AtBeginDocument{\\fontsize{14pt}{18.2pt}\\selectfont}\n'
        # Centraliza chapter e chapter* (book class)
        '\\makeatletter\n'
        '\\renewcommand{\\@makechapterhead}[1]{%\n'
        '  \\vspace*{50\\p@}\n'
        '  {\\parindent \\z@ \\centering \\normalfont\n'
        '    \\ifnum \\c@secnumdepth >\\m@ne \\huge\\bfseries \\thechapter\\space \\fi\n'
        '    \\Huge\\bfseries #1\\par\\nobreak\n'
        '    \\vskip 40\\p@\n'
        '  }}\n'
        '\\renewcommand{\\@makeschapterhead}[1]{%\n'
        '  \\vspace*{50\\p@}\n'
        '  {\\parindent \\z@ \\centering \\normalfont\n'
        '    \\Huge\\bfseries #1\\par\\nobreak\n'
        '    \\vskip 40\\p@\n'
        '  }}\n'
        # Centraliza section, subsection, subsubsection
        '\\renewcommand\\section{\\@startsection{section}{1}{\\z@}\n'
        '  {-3.5ex \\@plus -1ex \\@minus -.2ex}{2.3ex \\@plus.2ex}\n'
        '  {\\normalfont\\Large\\bfseries\\centering}}\n'
        '\\renewcommand\\subsection{\\@startsection{subsection}{2}{\\z@}\n'
        '  {-3.25ex\\@plus -1ex \\@minus -.2ex}{1.5ex \\@plus .2ex}\n'
        '  {\\normalfont\\large\\bfseries\\centering}}\n'
        '\\renewcommand\\subsubsection{\\@startsection{subsubsection}{3}{\\z@}\n'
        '  {-3.25ex\\@plus -1ex \\@minus -.2ex}{1.5ex \\@plus .2ex}\n'
        '  {\\normalfont\\normalsize\\bfseries\\centering}}\n'
        '\\makeatother\n'
        # Paragrafos: sem espaco entre eles, recuo de 1cm (exceto primeiro de cada secao)
        '\\setlength{\\parskip}{0pt}\n'
        '\\setlength{\\parindent}{1cm}\n'
    )

    with tempfile.NamedTemporaryFile(
        suffix='.tex', mode='w', encoding='utf-8', delete=False
    ) as hdr:
        hdr.write(latex_header)
        hdr_path = hdr.name

    try:
        cmd = [
            'pandoc', tmp_path,
            '-o', str(output_path),
            '--pdf-engine=xelatex',
            '--from=markdown-yaml_metadata_block+raw_tex',
            '-H', hdr_path,
            '-V', 'lang=pt-BR',
            '-V', 'fontsize=12pt',
            '-V', 'documentclass=book',
            '-V', 'geometry=paperwidth=16cm,paperheight=23cm,'
                  'top=1.5cm,bottom=1.5cm,inner=2cm,outer=1.5cm',
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"Exportado: {output_path}")
        else:
            print(result.stderr, file=sys.stderr)
            sys.exit(1)
    finally:
        os.unlink(tmp_path)
        os.unlink(hdr_path)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Uso: {sys.argv[0]} <projeto> [saida.pdf]")
        sys.exit(1)
    export(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
