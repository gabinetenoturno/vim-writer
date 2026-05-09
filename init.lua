-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader antes dos plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Opções base
vim.opt.encoding    = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.wrap        = true
vim.opt.linebreak   = true      -- quebra na borda da palavra
vim.opt.breakindent = true
vim.opt.number      = false
vim.opt.relativenumber = false
vim.opt.cursorline  = false
vim.opt.signcolumn  = "no"
vim.opt.statuscolumn = "%#Normal#    " -- margem esquerda, fundo idêntico ao Normal
vim.opt.mouse       = "a"
vim.opt.clipboard   = "unnamedplus"
vim.opt.undofile    = true
vim.opt.swapfile    = false
vim.opt.spelllang   = "pt_br"
vim.opt.spelloptions = "camel"
vim.opt.scrolloff   = 8
vim.opt.sidescrolloff = 8
vim.opt.updatetime  = 300

-- Neovide
if vim.g.neovide then
  vim.opt.guifont = "FreeMono:h14"       -- fonte base (tamanho normal)
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size   = 0
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_padding_top         = 8
  vim.g.neovide_padding_bottom      = 8
  vim.g.neovide_padding_left        = 80
  vim.g.neovide_padding_right       = 80

  vim.keymap.set({ "n", "i", "v" }, "<F11>", function()
    vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
  end)
end

-- Plugins
require("lazy").setup({

  -- Tema escuro
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon",
        styles = { italic = true, bold = true, transparency = false },
      })
      vim.cmd("colorscheme rose-pine-moon")
    end,
  },

  -- Modo foco: margem centralizada
  { "junegunn/goyo.vim",      cmd = "Goyo" },

  -- Modo foco: escurece parágrafos inativos
  {
    "junegunn/limelight.vim",
    cmd = "Limelight",
    init = function()
      -- rose-pine moon: overlay = #393552, texto normal = #e0def4
      -- parágrafos inativos ficam quase da cor do fundo
      vim.g.limelight_conceal_guifg  = "#393552"
      vim.g.limelight_conceal_ctermfg = 237
      vim.g.limelight_paragraph_span  = 0   -- só o parágrafo atual
      vim.g.limelight_priority        = -1  -- não sobrescrever spell highlights
    end,
  },

  -- Edição de prosa: wrap inteligente, movimentos por sentença
  {
    "preservim/vim-pencil",
    ft = { "markdown", "text" },
    init = function()
      vim.g["pencil#wrapModeDefault"] = "soft"
      vim.g["pencil#conceallevel"] = 3
    end,
  },

  -- Wiki para notas / worldbuilding / personagens
  {
    "vimwiki/vimwiki",
    init = function()
      vim.g.vimwiki_list = {{
        path = vim.fn.expand("~/WriteDir/notas/"),
        syntax = "markdown",
        ext  = ".md",
      }}
      vim.g.vimwiki_global_ext = 0   -- não tratar todo .md como vimwiki
    end,
  },

  -- Explorador de arquivos em árvore
  {
    "preservim/nerdtree",
    cmd = { "NERDTree", "NERDTreeToggle", "NERDTreeFind" },
    keys = {
      { "<leader>e", "<cmd>NERDTreeToggle<cr>", desc = "Explorador de arquivos" },
    },
    init = function()
      vim.g.NERDTreeShowHidden      = 1
      vim.g.NERDTreeMinimalUI       = 1
      vim.g.NERDTreeDirArrowExpandable  = "▸"
      vim.g.NERDTreeDirArrowCollapsible = "▾"
      vim.g.NERDTreeWinSize         = 30
    end,
  },

  -- Busca de arquivos e texto no manuscrito
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd  = "Telescope",
    keys = {
      { "<leader>f", "<cmd>Telescope find_files<cr>",  desc = "Abrir arquivo" },
      { "<leader>/", "<cmd>Telescope live_grep<cr>",   desc = "Buscar texto" },
      { "<leader>b", "<cmd>Telescope buffers<cr>",     desc = "Buffers abertos" },
    },
  },

}, {
  ui = {
    border = "single",
    icons = {
      cmd        = "[cmd]",
      config     = "[cfg]",
      event      = "[evt]",
      ft         = "[ft]",
      init       = "[init]",
      keys       = "[key]",
      plugin     = "[pkg]",
      runtime    = "[rt]",
      require    = "[req]",
      source     = "[src]",
      start      = "[+]",
      task       = "[task]",
      lazy       = "[lazy]",
      loaded     = "[+]",
      not_loaded = "[ ]",
      list       = { "*", "-", ">", "-" },
    },
  },
})

-- Typewriter mode: cursor desce livremente até o meio, depois para lá
local tw_group = vim.api.nvim_create_augroup("TypewriterMode", { clear = true })

-- Contador de palavras flutuante
local wc_buf, wc_win = nil, nil

local function wc_format(n)
  -- 1200 -> "1.200", 1200000 -> "1.200.000"
  return tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end

local function wc_update()
  if not (wc_buf and vim.api.nvim_buf_is_valid(wc_buf)) then return end
  local text = wc_format(vim.fn.wordcount().words)
  vim.api.nvim_buf_set_lines(wc_buf, 0, -1, false, { text })
  if wc_win and vim.api.nvim_win_is_valid(wc_win) then
    vim.api.nvim_win_set_config(wc_win, {
      col    = vim.o.columns - #text - 4,
      row    = vim.o.lines - 3,
      width  = #text,
      relative = "editor",
    })
  end
end

local function wc_show()
  wc_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[wc_buf].bufhidden = "wipe"
  vim.api.nvim_set_hl(0, "WcFloat", { fg = "#6e6a86", bg = "NONE" })
  wc_win = vim.api.nvim_open_win(wc_buf, false, {
    relative  = "editor",
    width     = 1,
    height    = 1,
    row       = vim.o.lines - 3,
    col       = vim.o.columns - 5,
    style     = "minimal",
    focusable = false,
    zindex    = 10,
  })
  vim.wo[wc_win].winhl = "Normal:WcFloat"
  wc_update()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = tw_group,
    callback = wc_update,
  })
end

local function wc_hide()
  if wc_win and vim.api.nvim_win_is_valid(wc_win) then
    vim.api.nvim_win_close(wc_win, true)
  end
  wc_win, wc_buf = nil, nil
end

local function typewriter_on()
  local mid = math.floor(vim.api.nvim_win_get_height(0) / 2)
  if vim.fn.winline() >= mid then
    vim.cmd("norm! zz")
  end
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = tw_group,
    callback = function()
      local m = math.floor(vim.api.nvim_win_get_height(0) / 2)
      if vim.fn.winline() >= m then
        vim.cmd("norm! zz")
      end
    end,
  })
  wc_show()
end

local function typewriter_off()
  vim.api.nvim_clear_autocmds({ group = tw_group })
  vim.opt_local.scrolloff = 8
  wc_hide()
end

-- Cores de fundo, tamanhos de fonte e forward declarations
local bg_normal   = "#232136"
local fg_text     = "#e0def4"
local font_normal = 14    -- tamanho da fonte no modo normal
local font_goyo   = 18    -- tamanho da fonte no modo foco (≈ h14 × 1.25)
local apply_insert_colors, apply_normal_colors

local function set_font(size)
  if vim.g.neovide then
    vim.opt.guifont = "FreeMono:h" .. size
  end
end

-- Integração Goyo + Limelight (canônica)
vim.api.nvim_create_autocmd("User", {
  pattern = "GoyoEnter",
  callback = function()
    vim.cmd("Limelight")
    typewriter_on()
    vim.opt.laststatus = 0                                 -- esconde status lines nos painéis do Goyo
    vim.api.nvim_set_hl(0, "GoyoPad", { bg = bg_normal })
    set_font(font_goyo)
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "GoyoLeave",
  callback = function()
    vim.cmd("Limelight!")
    vim.cmd("colorscheme rose-pine-moon")
    typewriter_off()
    set_font(font_normal)
    vim.opt.laststatus = 2
    apply_normal_colors()  -- restaura highlights após reset do colorscheme
  end,
})

-- Modo escrita: ativa tudo de uma vez
local writing_mode = false
local function toggle_writing()
  writing_mode = not writing_mode
  if writing_mode then
    vim.cmd("Goyo 88")
    vim.opt.spell = false
    vim.keymap.set("i", "<CR>", "<CR><CR>", { buffer = true })
    vim.notify("Modo escrita: ON", vim.log.levels.INFO)
  else
    vim.cmd("Goyo!")
    vim.opt.spell = true
    pcall(vim.keymap.del, "i", "<CR>", { buffer = true })
    vim.notify("Modo escrita: OFF", vim.log.levels.INFO)
  end
end

-- Exportar arquivo atual para PDF via pandoc
local function export_pdf()
  local src  = vim.fn.expand("%:p")
  local out  = vim.fn.expand("~/WriteDir/exportado/") .. vim.fn.expand("%:t:r") .. ".pdf"
  local cmd  = string.format("pandoc %q -o %q --pdf-engine=xelatex", src, out)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    vim.notify("Exportado: " .. out, vim.log.levels.INFO)
  else
    vim.notify("Erro pandoc:\n" .. result, vim.log.levels.ERROR)
  end
end

-- Keymaps principais
local map = function(m, k, v, d) vim.keymap.set(m, k, v, { desc = d, silent = true }) end

map("n", "<leader>w",  toggle_writing,               "Toggle modo escrita")
map("n", "<leader>s",  function()
  if writing_mode then
    vim.notify("Spell desativado no modo foco", vim.log.levels.WARN)
  else
    vim.opt.spell = not vim.opt.spell:get()
  end
end, "Toggle correção ortográfica")
map("n", "<leader>x",  export_pdf,                   "Exportar PDF")
map("n", "<leader>n",  "<cmd>VimwikiIndex<cr>",       "Notas (wiki)")
map("n", "<leader>e",  "<cmd>NERDTreeToggle<cr>",      "Explorador de arquivos")

-- Tamanho de fonte interativo: :Fz 18
-- Dentro do Goyo ajusta font_goyo; fora ajusta font_normal
vim.api.nvim_create_user_command("Fz", function(opts)
  local size = tonumber(opts.args)
  if not size or size < 8 or size > 72 then
    vim.notify("Fz: tamanho inválido (8–72)", vim.log.levels.WARN)
    return
  end
  if writing_mode then
    font_goyo = size
  else
    font_normal = size
  end
  set_font(size)
end, { nargs = 1, desc = "Definir tamanho da fonte" })
vim.cmd("cabbrev fz Fz")

-- j/k se movem por linha visual (essencial em prosa com wrap)
map("n", "j",  "gj",  "Linha visual abaixo")
map("n", "k",  "gk",  "Linha visual acima")
map("v", "j",  "gj",  "Linha visual abaixo")
map("v", "k",  "gk",  "Linha visual acima")

-- Navegar entre erros ortográficos com ]s / [s (built-in do Neovim)
-- Adicionar ao dicionário com zg, ignorar com zw

-- Configurações por tipo de arquivo
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.spell     = true
    vim.opt_local.wrap      = true
    vim.opt_local.linebreak = true
    vim.cmd("PencilSoft")
    vim.keymap.set("i", "--", "— ", { buffer = true })
  end,
})

-- Cursor: forma e cor por modo (bloco em Normal, barra em Insert)
vim.api.nvim_set_hl(0, "NormalCursor", { bg = "#908caa" })
vim.api.nvim_set_hl(0, "InsertCursor", { bg = "#c0bfca" })
vim.opt.guicursor = table.concat({
  "n-v-c:block-NormalCursor",
  "i-ci-ve:ver25-InsertCursor",
  "r-cr:hor20-NormalCursor",
}, ",")

-- Fundo por modo Insert/Normal
-- Em Insert: só muda o cursor
apply_insert_colors = function()
  vim.api.nvim_set_hl(0, "InsertCursor", { bg = "#c0bfca" })
end

-- Em Normal: restaura cursor; se veio do GoyoLeave, restaura highlights completos
apply_normal_colors = function()
  vim.api.nvim_set_hl(0, "NormalCursor", { bg = "#908caa" })
  vim.api.nvim_set_hl(0, "InsertCursor", { bg = "#c0bfca" })
  if writing_mode then
    vim.api.nvim_set_hl(0, "WcFloat", { fg = "#6e6a86", bg = "NONE" })
    return
  end
  -- Restaura highlights após reset do colorscheme (GoyoLeave)
  vim.api.nvim_set_hl(0, "Normal",       { bg = bg_normal, fg = fg_text })
  vim.api.nvim_set_hl(0, "NormalNC",     { bg = bg_normal })
  vim.api.nvim_set_hl(0, "NormalFloat",  { bg = bg_normal })
  vim.api.nvim_set_hl(0, "EndOfBuffer",  { bg = bg_normal, fg = "#393552" })
  vim.api.nvim_set_hl(0, "StatusLine",   { bg = "#2a273f", fg = "#908caa" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#2a273f", fg = "#6e6a86" })
  vim.api.nvim_set_hl(0, "TabLineFill",  { bg = bg_normal })
  vim.api.nvim_set_hl(0, "TabLine",      { bg = bg_normal, fg = "#6e6a86" })
  vim.api.nvim_set_hl(0, "TabLineSel",   { bg = bg_normal, fg = fg_text })
  vim.api.nvim_set_hl(0, "WinSeparator", { bg = bg_normal, fg = "#393552" })
  vim.api.nvim_set_hl(0, "VertSplit",    { bg = bg_normal, fg = "#393552" })
  vim.api.nvim_set_hl(0, "SignColumn",   { bg = bg_normal })
  vim.api.nvim_set_hl(0, "GoyoPad",     { bg = bg_normal })
  vim.cmd("redraw!")
end

vim.api.nvim_create_autocmd("InsertEnter", { callback = apply_insert_colors })
vim.api.nvim_create_autocmd("InsertLeave", { callback = apply_normal_colors })

-- Statusline mínima com contagem de palavras
vim.opt.laststatus = 2
vim.opt.statusline = "  %f %m%r  %=%{wordcount().words}p  %l:%c  "
