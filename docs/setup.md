# Setup — Neovim para escrita criativa (Arch Linux)

Documento para replicar o ambiente em uma nova máquina.

---

## Sistema

- OS: Arch Linux
- Display server: Wayland
- Terminal: Konsole (perfil "Escrita", fonte FreeMono 14)

---

## Pacotes instalados via pacman

```
sudo pacman -S neovim pandoc-cli fzf aspell-pt wl-clipboard
```

| Pacote       | Função                                             |
|--------------|----------------------------------------------------|
| neovim       | editor principal (terminal)                        |
| pandoc-cli   | exportar .md para PDF, DOCX, EPUB                 |
| fzf          | busca fuzzy no terminal                            |
| aspell-pt    | dicionário português para correção ortográfica     |
| wl-clipboard | suporte ao clipboard no Wayland (wl-copy/wl-paste) |

Nota: hunspell já estava instalado no sistema base.

Para exportar para PDF, é necessária uma engine LaTeX:
```
sudo pacman -S texlive-basic texlive-fontsrecommended
```

---

## Neovide (cliente GUI opcional)

Neovide é um cliente gráfico para Neovim que permite aumentar a fonte
automaticamente no modo foco e outras personalizações visuais.

```
sudo pacman -S neovide
paru -S ttf-courier-prime   (fonte instalada mas não usada atualmente)
```

Abrir com `neovide` em vez de `nvim`. Toda a config do init.lua é
compatível sem mudanças.

### Configurações ativas no Neovide

| Opção             | Valor        | Efeito                                      |
|-------------------|--------------|---------------------------------------------|
| guifont normal    | FreeMono:h14 | fonte base (ajustável com `:fz <n>`)        |
| guifont foco      | FreeMono:h18 | fonte no modo Goyo (ajustável com `:fz <n>`) |
| cursor_trail_size | 0            | sem rastro no cursor                        |
| scroll_animation  | 0.2s         | scroll suave                                |
| padding lateral   | 80px         | margens laterais                            |
| padding top/bot   | 8px          | respiro nas bordas                          |
| F11               | fullscreen   | alterna tela cheia                          |

---

## Estrutura de diretórios

```
~/WriteDir/
├── the-notebook/   → contos e rascunhos avulsos
├── romance-titulo/ → capítulos de um romance (uma pasta por projeto)
├── notas/          → wiki global de worldbuilding e personagens
└── exportado/      → PDFs gerados pelo pandoc
```

Criar pastas base:
```
mkdir -p ~/WriteDir/{notas,exportado}
```

Cada novo projeto é uma pasta dentro de `~/WriteDir/`.

---

## Configuração do Neovim

Arquivo: ~/.config/nvim/init.lua

O init.lua usa lazy.nvim como gerenciador de plugins, que se instala
automaticamente no primeiro nvim. Copiar o arquivo e abrir nvim é
suficiente — os plugins são baixados sozinhos.

### Plugins instalados via lazy.nvim

| Plugin                        | Função                                      |
|-------------------------------|---------------------------------------------|
| rose-pine/neovim              | tema escuro (variante: moon)                |
| junegunn/goyo.vim             | modo foco: margem centralizada (88 colunas) |
| junegunn/limelight.vim        | modo foco: escurece parágrafos inativos     |
| preservim/vim-pencil          | wrap e movimentos corretos para prosa       |
| vimwiki/vimwiki               | wiki em Markdown para notas e worldbuilding |
| preservim/nerdtree            | explorador de arquivos em árvore            |
| nvim-telescope/telescope.nvim | busca de arquivos e texto no manuscrito     |
| nvim-lua/plenary.nvim         | dependência do Telescope                    |

---

## Modo foco (writing mode)

Ativado com `<Space>w`. Combina:

- **Goyo** — margem centralizada, interface limpa
- **Limelight** — parágrafos inativos escurecidos (#393552, quase fundo);
  parágrafo atual permanece na cor normal do texto, sem destaque de fundo
- **Typewriter scroll** — cursor desce livremente até o meio da tela,
  depois fica fixo ali e o texto sobe (funciona com linhas soft-wrapped)
- **Contador de palavras** — janela flutuante discreta no canto inferior
  direito, formato brasileiro (ex: 1.200), cor #6e6a86
- **Enter duplo** — Enter insere linha em branco (separador de parágrafo
  Markdown); desativa ao sair do modo foco
- **Spell desativado** — sem sublinhados durante a escrita;
  spell volta ao sair do modo foco
- **Neovide** — fonte aumenta 25% automaticamente ao entrar no modo foco

---

## Indicador de modo Insert

O cursor muda de forma e cor ao entrar em Insert mode:
- Normal: bloco cinza (#908caa)
- Insert: barra fina cinza-claro (#c0bfca)

Nenhuma mudança de fundo ocorre — o indicador é exclusivamente o cursor.

---

## Correção ortográfica

- Ativa automaticamente ao abrir arquivos .md e .txt
- Desativa no modo foco para não distrair
- O Neovim baixa o dicionário pt_br automaticamente na primeira vez
- Navegar entre erros: `]s` / `[s`
- Adicionar palavra ao dicionário pessoal: `zg`
- Marcar palavra como errada: `zw`

---

## Atalhos principais

| Tecla / Comando | Ação                                                        |
|-----------------|-------------------------------------------------------------|
| `<Space>w`      | liga/desliga modo foco                                      |
| `<Space>s`      | liga/desliga correção ortográfica                           |
| `<Space>x`      | exporta arquivo atual para PDF                              |
| `<Space>n`      | abre o wiki de notas                                        |
| `<Space>e`      | abre/fecha NERDTree                                         |
| `<Space>f`      | busca arquivo (Telescope)                                   |
| `<Space>/`      | busca texto no manuscrito (Telescope)                       |
| `<Space>b`      | lista buffers abertos                                       |
| `j` / `k`       | movem por linha visual (não linha física)                   |
| `]s` / `[s`     | próximo/anterior erro ortográfico                           |
| `zg`            | adiciona palavra ao dicionário                              |
| `F11`           | fullscreen (Neovide apenas)                                 |
| `:fz <n>`       | define tamanho da fonte; persiste por modo (normal ou Goyo) |

---

## NERDTree — explorador de arquivos

Abrir/fechar com `<Space>e`. Para alternar entre o NERDTree e o editor:

| Atalho       | Ação                              |
|--------------|-----------------------------------|
| `Ctrl+w w`   | alterna entre as duas janelas     |
| `Ctrl+w h`   | vai para o NERDTree (esquerda)    |
| `Ctrl+w l`   | vai para o editor (direita)       |

### Operações de arquivo (pressionar `m` sobre um nó)

| Tecla no menu | Ação                                                    |
|---------------|---------------------------------------------------------|
| `a`           | criar arquivo ou pasta (terminar com `/` para pasta)    |
| `d`           | deletar                                                 |
| `m`           | mover / renomear                                        |
| `c`           | copiar                                                  |

### Configurações ativas

| Opção              | Valor | Efeito                        |
|--------------------|-------|-------------------------------|
| ShowHidden         | 1     | exibe arquivos ocultos (`.x`) |
| MinimalUI          | 1     | sem cabeçalho/rodapé          |
| WinSize            | 30    | largura do painel             |
| DirArrowExpandable | ▸     | seta de pasta fechada         |
| DirArrowCollapsible| ▾     | seta de pasta aberta          |

---

## Autocorreção

Ativa apenas em arquivos .md e .txt:

| Digitado | Resultado |
|----------|-----------|
| `--`     | `— `      |

---

## Observações de compatibilidade

- lazy.nvim configurado com ícones ASCII para não depender de Nerd Fonts.
  Se instalar uma Nerd Font no futuro, o bloco ui.icons pode ser removido
  do init.lua para voltar ao padrão visual do lazy.nvim.

- wl-clipboard é obrigatório no Wayland. Em ambientes X11, usar xclip ou
  xsel no lugar.

- O caminho ~/ficção/ usa UTF-8 (ç). Arch Linux usa UTF-8 por padrão,
  então funciona sem configuração adicional.

- O indicador de modo Insert (fundo escuro) ignora janelas flutuantes
  como o Telescope para não quebrar a UI de busca.

---

## Replicar em nova máquina

```
# 1. Instalar pacotes base
sudo pacman -S neovim pandoc-cli fzf aspell-pt wl-clipboard

# 2. Instalar Neovide (opcional, para GUI)
sudo pacman -S neovide

# 3. Criar estrutura de diretórios
mkdir -p ~/WriteDir/{notas,exportado}

# 4. Copiar configuração
mkdir -p ~/.config/nvim
cp init.lua ~/.config/nvim/

# 5. Abrir o Neovim — lazy.nvim instala tudo automaticamente
nvim
```
