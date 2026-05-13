#!/usr/bin/env python3
"""
export-book.py — Exporta Draft/ de um projeto para PDF polido.
Uso: python3 export-book.py <caminho-do-projeto> [nome-saida.pdf]

Convencoes de nomenclatura em Draft/:
  Front-matter/ (dir sem numero inicial):
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
import tomllib
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent


def sort_key(name: str):
    m = re.match(r'^(\d+)', name)
    return (int(m.group(1)) if m else 0, name)


def collect_files(draft: Path, include_front_matter: bool = True):
    """
    Retorna lista ordenada de (Path, break_before, is_pretextual, is_title_page).
      break_before: 'odd' | 'even' | 'cont'
      is_pretextual: True para arquivos do front-matter
      is_title_page: True apenas para o primeiro arquivo 'a' do front-matter
    """
    subdirs = sorted(draft.iterdir(), key=lambda d: sort_key(d.name))
    subdirs = [d for d in subdirs if d.is_dir()]

    pre_dirs   = [d for d in subdirs if not re.match(r'^\d', d.name)] if include_front_matter else []
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


def _render_md_lines(content: str) -> list[str]:
    """Converte linhas markdown para comandos LaTeX (sem envoltório de página)."""
    sizes = ['\\Huge', '\\huge', '\\LARGE', '\\Large', '\\large', '\\normalsize']
    out = []
    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            out.append('\\vspace{0.8em}')
            continue
        m = re.match(r'^(#{1,6})\s+(.+)', line)
        if m:
            level = len(m.group(1))
            text  = md_inline_to_latex(m.group(2).strip())
            size  = sizes[min(level - 1, 5)]
            out.append(f'{{{size} {text}\\par}}')
        else:
            out.append(f'{{\\normalsize {md_inline_to_latex(line)}\\par}}')
    return out


def format_centered_page(content: str, timestamp: str = None) -> str:
    """Página pré-textual centralizada (folha de rosto, agradecimentos, etc.)."""
    lines = ['\\begin{pretext}', '\\thispagestyle{empty}', '\\vspace*{\\fill}', '\\centering']
    lines += _render_md_lines(content)
    lines.append('\\vspace*{\\fill}')
    if timestamp:
        lines += [f'{{\\small {timestamp}\\par}}', '\\vspace*{1em}']
    lines.append('\\end{pretext}')
    return '\n'.join(lines)


def format_left_page(content: str) -> str:
    """Página verso (dados do livro): alinhada à esquerda, sem centralização."""
    lines = ['\\begin{pretext}', '\\thispagestyle{empty}', '\\raggedright']
    lines += _render_md_lines(content)
    lines.append('\\end{pretext}')
    return '\n'.join(lines)


def build_combined(files, toc_depth: int = 1) -> str:
    # Contador corre desde a capa (pag 1 = folha de rosto), mas so aparece no conteudo
    parts = ['\\pagenumbering{arabic}\n\\pagestyle{empty}\n\n']
    prev_pretextual = True
    timestamp = datetime.now().strftime('%d/%m/%Y - %H:%M')

    for i, (filepath, break_before, is_pretextual, is_title) in enumerate(files):
        content = filepath.read_text(encoding='utf-8').strip()

        transitioning = prev_pretextual and not is_pretextual
        prev_pretextual = is_pretextual

        if transitioning:
            # cleardoublepage aqui ja cobre o break_before='odd' do primeiro conto
            parts.append('\n\n\\cleardoublepage\n\\pagestyle{plain}\n\n')
        elif i > 0:
            if break_before == 'odd':
                parts.append('\n\n\\cleardoublepage\n\n')
            elif break_before == 'even':
                parts.append('\n\n\\clearpage\n\n')
            else:
                parts.append('\n\n')

        if is_pretextual:
            if re.search(r'sum[aá]rio', filepath.stem, re.IGNORECASE):
                # addtocontents escreve no .toc antes das entradas; na 2a passagem
                # do xelatex sobrescreve o \thispagestyle{plain} do book class
                parts.append(
                    '\\addtocontents{toc}{\\protect\\thispagestyle{empty}}\n'
                    f'\\setcounter{{tocdepth}}{{{toc_depth}}}\n'
                    '\\tableofcontents'
                )
            elif break_before == 'even':
                # sufixo 'b': verso da folha de rosto, sempre pagina 2, alinhado a esquerda
                parts.append(format_left_page(content))
            elif is_title:
                parts.append(format_centered_page(content, timestamp))
            else:
                parts.append(format_centered_page(content))
        else:
            if break_before == 'odd' and not content.startswith('#'):
                content = '\\noindent ' + content
            parts.append(content)

    return ''.join(parts)


def load_settings(path: Path) -> dict:
    if path.exists():
        with open(path, 'rb') as f:
            return tomllib.load(f)
    return {}


def build_latex_header(cfg: dict) -> str:
    f = cfg.get('font', {})
    c = cfg.get('content', {})

    family      = f.get('family',      'Whitman')
    path        = f.get('path',        '/usr/local/share/fonts/w/')
    upright     = f.get('upright',     'Whitman_RomanOsF')
    italic      = f.get('italic',      'Whitman_ItalicOsF')
    bold        = f.get('bold',        'Whitman_BoldOsF')
    bold_italic = f.get('bold_italic', 'Whitman_ItalicOsF')
    extension   = f.get('extension',   '.ttf')
    size_pt     = f.get('size_pt',     13)
    leading_pt  = f.get('leading_pt',  16.9)
    indent_cm   = c.get('paragraph_indent_cm', 1.0)

    return (
        '\\usepackage{fontspec}\n'
        '\\setmainfont[\n'
        f'  Path={path},\n'
        f'  UprightFont={upright},\n'
        f'  ItalicFont={italic},\n'
        f'  BoldFont={bold},\n'
        f'  BoldItalicFont={bold_italic},\n'
        f'  Extension={extension},\n'
        f']{{{family}}}\n'
        f'\\AtBeginDocument{{\\fontsize{{{size_pt}pt}}{{{leading_pt}pt}}\\selectfont}}\n'
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
        '\\setlength{\\parskip}{0pt}\n'
        f'\\setlength{{\\parindent}}{{{indent_cm}cm}}\n'
        '\\newenvironment{pretext}{}{}\n'
    )


def export(project_dir: str, output_name: str = None, profile: str = 'settings'):
    cfg = load_settings(SCRIPT_DIR / 'export-settings' / f'{profile}.toml')

    project = Path(project_dir).resolve()
    draft   = project / 'Draft'

    if not draft.exists():
        print(f"Erro: diretorio Draft/ nao encontrado em {project}", file=sys.stderr)
        sys.exit(1)

    export_dir = Path.home() / 'WriteDir' / 'exportado'
    export_dir.mkdir(parents=True, exist_ok=True)

    if not output_name:
        output_name = project.name + '.pdf'
    output_path = export_dir / output_name

    c          = cfg.get('content', {})
    include_fm = c.get('include_front_matter', True)
    toc_depth  = c.get('toc_depth', 0)
    files      = collect_files(draft, include_fm)
    combined   = build_combined(files, toc_depth)

    with tempfile.NamedTemporaryFile(
        suffix='.md', mode='w', encoding='utf-8', delete=False
    ) as tmp:
        tmp.write(combined)
        tmp_path = tmp.name

    with tempfile.NamedTemporaryFile(
        suffix='.tex', mode='w', encoding='utf-8', delete=False
    ) as hdr:
        hdr.write(build_latex_header(cfg))
        hdr_path = hdr.name

    p    = cfg.get('page', {})
    w    = p.get('width_cm',         16)
    h    = p.get('height_cm',        23)
    top  = p.get('margin_top_cm',   1.5)
    bot  = p.get('margin_bottom_cm', 1.5)
    inn  = p.get('margin_inner_cm',  2.0)
    out  = p.get('margin_outer_cm',  1.5)
    geo  = (f"paperwidth={w}cm,paperheight={h}cm,"
            f"top={top}cm,bottom={bot}cm,inner={inn}cm,outer={out}cm")

    lang = cfg.get('content', {}).get('language', 'pt-BR')
    size = cfg.get('font', {}).get('size_pt', 13)

    try:
        cmd = [
            'pandoc', tmp_path,
            '-o', str(output_path),
            '--pdf-engine=xelatex',
            '--from=markdown-yaml_metadata_block+raw_tex',
            '-H', hdr_path,
            '-V', f'lang={lang}',
            '-V', f'fontsize={size}pt',
            '-V', 'documentclass=book',
            '-V', f'geometry={geo}',
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
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('project')
    p.add_argument('--output', default=None)
    p.add_argument('--profile', default='settings')
    args = p.parse_args()
    export(args.project, args.output, args.profile)
