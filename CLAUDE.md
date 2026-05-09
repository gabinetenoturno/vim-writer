# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este repositório

Backup e documentação de um ambiente Neovim/Neovide configurado para escrita criativa de ficção no Arch Linux. Não é um projeto de software — é um conjunto de arquivos de configuração e documentação a serem replicados em novas máquinas.

## Arquivos principais

- **`init.lua`** — única fonte de verdade da configuração do Neovim. Qualquer mudança de comportamento do editor acontece aqui. Após editar, sincronizar para a instalação ativa com `cp init.lua ~/.config/nvim/init.lua`.
- **`escrita.desktop`** — atalho KDE. Após editar, reinstalar com `cp escrita.desktop ~/.local/share/applications/ && update-desktop-database ~/.local/share/applications/`.
- **`docs/setup.md`** — guia de instalação completo para nova máquina.
- **`docs/workflow.md`** — referência de uso do dia a dia.

## Convenções do init.lua

O arquivo é um único `init.lua` (sem módulos separados) para facilitar a cópia em uma nova máquina. A estrutura interna segue esta ordem:

1. Bootstrap do lazy.nvim
2. Opções globais (`vim.opt.*`)
3. Bloco Neovide (guardado por `if vim.g.neovide`)
4. Declaração dos plugins (`require("lazy").setup(...)`)
5. Lógica Lua: typewriter scroll, contador de palavras, toggle do modo escrita, exportação PDF
6. Keymaps (`<leader>` = `<Space>`)
7. Autocmds por FileType
8. Highlights de cursor e modo Insert

## Diretórios do sistema (fora do repo)

| Caminho | Função |
|---|---|
| `~/.config/nvim/init.lua` | config ativa do Neovim |
| `~/.local/share/applications/escrita.desktop` | atalho instalado no KDE |
| `~/WriteDir/` | diretório raiz de todos os projetos de escrita |
| `~/WriteDir/notas/` | wiki VimWiki (apontado no init.lua) |
| `~/WriteDir/exportado/` | PDFs gerados pelo pandoc |

## Git

Branch única: `main`. Sempre commitar e fazer push direto na main — não há PRs, branches de feature ou code review neste repo.

## Fluxo de alterações

1. Aplicar a mudança no `init.lua` (ou outro arquivo) e sincronizar para `~/.config/nvim/init.lua`
2. Pedir ao usuário para testar
3. Após confirmação: atualizar a documentação relevante (`docs/setup.md` ou `docs/workflow.md`), commitar e fazer push

## Sincronizar após mudanças

```bash
# Aplicar init.lua na instalação ativa
cp init.lua ~/.config/nvim/init.lua

# Reinstalar atalho KDE
cp escrita.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

## Plugins gerenciados pelo lazy.nvim

Os plugins não estão neste repo — lazy.nvim os baixa automaticamente na primeira abertura do Neovim. O arquivo `lazy-lock.json` (em `~/.local/share/nvim/lazy/lazy-lock.json`) fixa as versões, mas não é versionado aqui por decisão intencional (portabilidade).
