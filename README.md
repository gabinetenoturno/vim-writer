# vim-writer

Configuração do Neovim para escrita criativa de ficção no Arch Linux,
com suporte a Neovide como frontend gráfico opcional.

O objetivo é um ambiente minimalista, sem distrações, voltado para
manuscritos em Markdown com exportação para PDF via pandoc.

---

## O que está neste repositório

```
vim-writer/
├── init.lua            → configuração completa do Neovim (copiar para ~/.config/nvim/)
├── escrita.desktop     → atalho KDE que abre o Neovide em ~/WriteDir/
├── docs/
│   ├── setup.md        → guia de instalação e referência de todas as opções
│   └── workflow.md     → guia de uso do dia a dia
└── README.md
```

---

## Instalação rápida

```bash
# 1. Pacotes base
sudo pacman -S neovim pandoc-cli fzf aspell-pt wl-clipboard

# 2. Para exportar PDF
sudo pacman -S texlive-basic texlive-fontsrecommended

# 3. Neovide (GUI)
sudo pacman -S neovide

# 4. Estrutura de diretórios
mkdir -p ~/WriteDir/{notas,exportado}

# 5. Instalar a configuração
mkdir -p ~/.config/nvim
cp init.lua ~/.config/nvim/

# 6. Instalar o atalho do KDE
cp escrita.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/

# 7. Abrir o Neovim — lazy.nvim instala os plugins automaticamente
nvim
```

---

## Funcionalidades

### Modo foco (`<Space>w`)

Combina quatro comportamentos ao mesmo tempo:

- **Goyo** — centraliza o texto em 88 colunas, esconde a interface
- **Limelight** — escurece todos os parágrafos exceto o atual
- **Typewriter scroll** — o cursor fica fixo no meio da tela; o texto sobe
- **Contador de palavras** — número discreto no canto inferior direito, formato brasileiro (1.200)

No Neovide, a fonte aumenta 25% ao entrar no modo foco e volta ao normal ao sair.

### Indicador de modo Insert

O fundo da tela muda de `#232136` (Normal) para `#090e13` (Insert).
O cursor muda de bloco cinza para barra fina rosa.

### Correção ortográfica

Ativa automaticamente em `.md` e `.txt`, desativa no modo foco para não distrair.
O dicionário `pt_br` é baixado pelo Neovim na primeira vez.

### Exportação para PDF

`<Space>x` chama o pandoc com xelatex e salva o resultado em `~/ficção/exportado/`.

### Wiki de notas

`<Space>n` abre o VimWiki apontado para `~/ficção/notas/`, em Markdown.
Útil para personagens, worldbuilding e pesquisa.

---

## Plugins

| Plugin              | Função                                  |
|---------------------|-----------------------------------------|
| rose-pine (moon)    | tema escuro                             |
| goyo.vim            | modo foco com margens centralizadas     |
| limelight.vim       | destaque do parágrafo atual             |
| vim-pencil          | wrap e movimentos corretos para prosa   |
| vimwiki             | wiki de notas em Markdown               |
| nerdtree            | explorador de arquivos em árvore        |
| telescope.nvim      | busca fuzzy de arquivos e texto         |

Gerenciador: [lazy.nvim](https://github.com/folke/lazy.nvim) — instala tudo automaticamente.
Configurado com ícones ASCII, sem dependência de Nerd Fonts.

---

## Atalhos

| Tecla        | Ação                                      |
|--------------|-------------------------------------------|
| `<Space>w`   | liga/desliga modo foco                    |
| `<Space>s`   | liga/desliga correção ortográfica         |
| `<Space>x`   | exporta arquivo atual para PDF            |
| `<Space>n`   | abre o wiki de notas                      |
| `<Space>e`   | abre/fecha NERDTree                       |
| `<Space>f`   | busca arquivo (Telescope)                 |
| `<Space>/`   | busca texto no manuscrito (Telescope)     |
| `<Space>b`   | lista buffers abertos                     |
| `j` / `k`    | movem por linha visual (não linha física) |
| `]s` / `[s`  | próximo/anterior erro ortográfico         |
| `zg`         | adiciona palavra ao dicionário            |
| `F11`        | fullscreen (Neovide apenas)               |

---

## Documentação detalhada

- [docs/setup.md](docs/setup.md) — instalação passo a passo, todas as opções e observações de compatibilidade
- [docs/workflow.md](docs/workflow.md) — uso do dia a dia, exemplos de sessão completa

---

## Ambiente

- OS: Arch Linux / Wayland
- Terminal: Konsole (perfil "Escrita", FreeMono 14)
- Editor: Neovim + Neovide
- Diretório de projetos: `~/WriteDir/`
- Atalho KDE: "Escrita" — abre o Neovide direto em `~/WriteDir/`
