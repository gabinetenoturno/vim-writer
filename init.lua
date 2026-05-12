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

-- Forward declarations (usadas dentro do config do lazy antes de serem definidas abaixo)
local goyo_width, save_fonts

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
  { "junegunn/goyo.vim", cmd = "Goyo", config = function()
    -- Intercepta :Goyo N (inclusive no redimensionamento) para persistir a largura
    vim.api.nvim_create_user_command("Goyo", function(opts)
      local arg = vim.trim(opts.args or "")
      if not opts.bang and arg ~= "" then
        goyo_width = arg
        save_fonts()
      end
      vim.cmd("call goyo#execute(" .. (opts.bang and 1 or 0) .. ", " .. vim.fn.string(arg) .. ")")
    end, { force = true, nargs = "?", bang = true })
  end },

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
      vim.g.NERDTreeShowHidden          = 1
      vim.g.NERDTreeMinimalUI           = 1
      vim.g.NERDTreeDirArrowExpandable  = "▸"
      vim.g.NERDTreeDirArrowCollapsible = "▾"
      vim.g.NERDTreeWinSize             = 30
      vim.g.NERDTreeQuitOnOpen          = 1
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
goyo_width        = "88"
local apply_insert_colors, apply_normal_colors

local function set_font(size)
  if vim.g.neovide then
    vim.opt.guifont = "FreeMono:h" .. size
  end
end

local font_config = vim.fn.stdpath("data") .. "/vim-writer-fonts.lua"

save_fonts = function()
  local f = io.open(font_config, "w")
  if f then
    f:write(string.format("return { normal = %d, goyo = %d, goyo_width = %q }\n", font_normal, font_goyo, goyo_width))
    f:close()
  end
end

do
  local ok, cfg = pcall(dofile, font_config)
  if ok and type(cfg) == "table" then
    font_normal = cfg.normal      or font_normal
    font_goyo   = cfg.goyo        or font_goyo
    goyo_width  = cfg.goyo_width  or goyo_width
    set_font(font_normal)
  end
end

-- Sessão de foco: estado e helpers (antes dos autocmds Goyo para poder referenciá-los)
local ns_state = { timer = nil, buf = nil, win = nil, remaining = 0, words_start = 0, mins = 0, file = "" }

local function ns_fmt(s)
  return string.format("%02d:%02d", math.floor(s / 60), s % 60)
end

local function ns_win_close()
  if ns_state.win and vim.api.nvim_win_is_valid(ns_state.win) then
    vim.api.nvim_win_close(ns_state.win, true)
  end
  ns_state.win = nil
  ns_state.buf = nil
end

local function ns_win_open()
  vim.api.nvim_set_hl(0, "NsFloat", { fg = "#6e6a86", bg = "NONE" })
  ns_state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ns_state.buf].bufhidden = "wipe"
  ns_state.win = vim.api.nvim_open_win(ns_state.buf, false, {
    relative  = "editor",
    width     = 5,
    height    = 1,
    row       = vim.o.lines - 3,
    col       = 4,
    style     = "minimal",
    focusable = false,
    zindex    = 50,
  })
  vim.wo[ns_state.win].winhl = "Normal:NsFloat"
  vim.api.nvim_buf_set_lines(ns_state.buf, 0, -1, false, { ns_fmt(ns_state.remaining) })
end

local function ns_tick()
  if not (ns_state.buf and vim.api.nvim_buf_is_valid(ns_state.buf)) then return end
  vim.api.nvim_buf_set_lines(ns_state.buf, 0, -1, false, { ns_fmt(ns_state.remaining) })
end

local function ns_save_csv(written, ppm)
  local path = vim.fn.expand("~/WriteDir/sessoes.csv")
  local doc  = ns_state.file:gsub('"', '""')
  local row  = string.format('%s,%s,%d,%d,%d,"%s"',
    os.date("%Y-%m-%d"), os.date("%H:%M"), ns_state.mins, written, ppm, doc)
  local lines = {}
  local rf = io.open(path, "r")
  if rf then
    for line in rf:lines() do table.insert(lines, line) end
    rf:close()
    table.insert(lines, 2, row)   -- após o cabeçalho
  else
    lines = { "data,hora,minutos,palavras,ppm,documento", row }
  end
  local wf = io.open(path, "w")
  if not wf then
    vim.api.nvim_echo({ { "  erro: não foi possível salvar em " .. path, "ErrorMsg" } }, true, {})
    return
  end
  wf:write(table.concat(lines, "\n") .. "\n")
  wf:close()
  vim.api.nvim_echo({ { "  salvo em ~/WriteDir/sessoes.csv", "Normal" } }, true, {})
end

local function ns_today_total()
  local path  = vim.fn.expand("~/WriteDir/sessoes.csv")
  local f     = io.open(path, "r")
  if not f then return 0 end
  local today = os.date("%Y-%m-%d")
  local total = 0
  local skip  = true
  for line in f:lines() do
    if skip then skip = false
    else
      -- formato: data,hora,minutos,palavras,ppm,documento
      local date, palavras = line:match('^([^,]+),[^,]+,[^,]+,([^,]+)')
      if date == today then total = total + (tonumber(palavras) or 0) end
    end
  end
  f:close()
  return total
end

local function ns_show_stats(written, ppm)
  local hoje_total = ns_today_total() + written
  local hoje_str   = "  hoje: " .. wc_format(hoje_total) .. " palavras"
  local lines = {
    "",
    hoje_str,
    "",
    "  fim do foco",
    "",
    string.format("  tempo     %d min", ns_state.mins),
    string.format("  palavras  %d",     written),
    string.format("  média     %d ppm", ppm),
    "",
    "  salvar? [y] sim   [n] não",
    "",
  }
  local w    = 32
  local sbuf = vim.api.nvim_create_buf(false, true)
  vim.bo[sbuf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(sbuf, 0, -1, false, lines)
  vim.bo[sbuf].modifiable = false
  vim.api.nvim_set_hl(0, "NsStats",     { fg = "#e0def4", bg = "#2a273f" })
  vim.api.nvim_set_hl(0, "NsStatsBold", { fg = "#e0def4", bg = "#2a273f", bold = true })
  vim.api.nvim_set_hl(0, "NsBorder",    { fg = "#393552", bg = "#2a273f" })
  vim.api.nvim_buf_add_highlight(sbuf, -1, "NsStatsBold", 1, 0, -1)  -- linha "hoje" em negrito
  local swin = vim.api.nvim_open_win(sbuf, true, {
    relative  = "editor",
    width     = w,
    height    = #lines,
    row       = math.floor((vim.o.lines   - #lines) / 2),
    col       = math.floor((vim.o.columns - w)      / 2),
    style     = "minimal",
    border    = "single",
    zindex    = 60,
    focusable = true,
  })
  vim.wo[swin].winhl = "Normal:NsStats,FloatBorder:NsBorder"

  local function close(save)
    if vim.api.nvim_win_is_valid(swin) then vim.api.nvim_win_close(swin, true) end
    if save then
      ns_save_csv(written, ppm)
    end
  end
  local o = { buffer = sbuf, nowait = true, silent = true }
  vim.keymap.set("n", "y",     function() close(true)  end, o)
  vim.keymap.set("n", "Y",     function() close(true)  end, o)
  vim.keymap.set("n", "<CR>",  function() close(true)  end, o)
  vim.keymap.set("n", "n",     function() close(false) end, o)
  vim.keymap.set("n", "N",     function() close(false) end, o)
  vim.keymap.set("n", "<Esc>", function() close(false) end, o)
  vim.keymap.set("n", "q",     function() close(false) end, o)
end

local function ns_finish()
  ns_state.timer:stop()
  ns_state.timer:close()
  ns_state.timer     = nil
  ns_state.remaining = 0
  ns_win_close()
  -- Palavras capturadas aqui, antes do InsertLeave, para não contar extras
  local written = math.max(0, vim.fn.wordcount().words - ns_state.words_start)
  local ppm     = ns_state.mins > 0 and math.floor(written / ns_state.mins) or 0
  vim.fn.jobstart({
    "notify-send",
    "-u", "critical",
    "-i", "appointment-soon",
    "-t", "8000",
    string.format("⏳ %d palavras · %d ppm", written, ppm),
    string.format("Sessão de %d min encerrada.", ns_state.mins),
  })
  local function show() ns_show_stats(written, ppm) end
  if vim.fn.mode() == "i" then
    vim.api.nvim_create_autocmd("InsertLeave", { once = true, callback = show })
  else
    show()
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
    if ns_state.timer then vim.schedule(function() ns_win_close(); ns_win_open() end) end
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
    if ns_state.timer then vim.schedule(function() ns_win_close(); ns_win_open() end) end
  end,
})

-- Modo escrita: ativa tudo de uma vez
local writing_mode = false
local function toggle_writing()
  writing_mode = not writing_mode
  if writing_mode then
    vim.cmd("Goyo " .. goyo_width)
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

-- Modo leitura: highlights de revisão de prosa
local reading_mode    = false
local reading_matches = {}

local reading_hls = {
  LeituraDialogo     = { fg = "#9ccfd8" },
  LeituraDialogCurto = { fg = "#9ccfd8", italic = true },
  LeituraItalico     = { fg = "#c4a7e7", italic = true },
  LeituraComentario  = { fg = "#6e6a86" },
  LeituraDiscDireto  = { fg = "#f6c177" },
}

local reading_patterns = {
  { hl = "LeituraDialogo",     pat = [[\v^—.*]],               pri = 10 },
  { hl = "LeituraDialogCurto", pat = [[\v—[^—]+—]],           pri = 11 },
  { hl = "LeituraItalico",     pat = [[\v\*[^*]+\*]],         pri = 10 },
  { hl = "LeituraComentario",  pat = [=[\v\[[^\]]+\]]=],       pri = 10 },
  { hl = "LeituraDiscDireto",  pat = [[\v("[^"]+"|"[^"]+")]], pri = 10 },
}

local function reading_apply_hls()
  for name, opts in pairs(reading_hls) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local function reading_on()
  reading_apply_hls()
  for _, item in ipairs(reading_patterns) do
    table.insert(reading_matches, vim.fn.matchadd(item.hl, item.pat, item.pri))
  end
  vim.notify("Modo leitura: ON", vim.log.levels.INFO)
end

local function reading_off()
  for _, id in ipairs(reading_matches) do
    pcall(vim.fn.matchdelete, id)
  end
  reading_matches = {}
  vim.notify("Modo leitura: OFF", vim.log.levels.INFO)
end

local function toggle_reading()
  reading_mode = not reading_mode
  if reading_mode then reading_on() else reading_off() end
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

-- Exportar livro completo (Rascunho/ do projeto atual)
vim.api.nvim_create_user_command("ExportBook", function(opts)
  -- Sobe a partir do arquivo aberto até encontrar um dir com Rascunho/
  local project = nil
  local file = vim.fn.expand("%:p")
  if file ~= "" then
    local dir = vim.fn.fnamemodify(file, ":h")
    while dir ~= "/" do
      if vim.uv.fs_stat(dir .. "/Rascunho") then
        project = dir
        break
      end
      dir = vim.fn.fnamemodify(dir, ":h")
    end
  end
  if not project then
    vim.notify("Rascunho/ não encontrado a partir do arquivo atual.", vim.log.levels.ERROR)
    return
  end

  local script  = vim.fn.expand("~/DevDir/vim-writer/export-book.py")
  local out_arg = opts.args ~= "" and string.format(" %q", opts.args) or ""
  vim.notify("Exportando: " .. vim.fn.fnamemodify(project, ":t"), vim.log.levels.INFO)
  local result = vim.fn.system(string.format("python3 %q %q%s", script, project, out_arg))
  if vim.v.shell_error == 0 then
    vim.notify(vim.trim(result), vim.log.levels.INFO)
  else
    vim.notify("Erro na exportação:\n" .. result, vim.log.levels.ERROR)
  end
end, { nargs = "?", desc = "Exportar livro completo para PDF" })

-- Sessão de foco: comando
vim.api.nvim_create_user_command("Sn", function(opts)
  if ns_state.timer then
    ns_state.timer:stop()
    ns_state.timer:close()
    ns_state.timer     = nil
    ns_state.remaining = 0
    ns_win_close()
    vim.api.nvim_echo({ { "  Sessão cancelada.", "Normal" } }, true, {})
    return
  end

  local mins = tonumber(opts.args) or 15
  if mins < 1 or mins > 180 then
    vim.notify("Ns: use entre 1 e 180 minutos", vim.log.levels.WARN)
    return
  end

  ns_state.mins        = mins
  ns_state.words_start = vim.fn.wordcount().words
  ns_state.file        = vim.fn.expand("%:p")
  ns_state.remaining   = mins * 60
  ns_win_open()

  ns_state.timer = vim.uv.new_timer()
  ns_state.timer:start(1000, 1000, vim.schedule_wrap(function()
    ns_state.remaining = ns_state.remaining - 1
    if ns_state.remaining <= 0 then
      ns_finish()
      return
    end
    ns_tick()
  end))

  vim.notify(string.format("Sessão: %d min", mins), vim.log.levels.INFO)
end, { nargs = "?", desc = "Sessão de foco" })
vim.cmd("cabbrev sn Sn")

vim.api.nvim_create_user_command("Sd", function()
  local total = ns_today_total()
  vim.api.nvim_echo({
    { "  hoje: ", "Normal" },
    { wc_format(total) .. " palavras", "NsStatsBold" },
  }, true, {})
end, { desc = "Total de palavras do dia" })
vim.cmd("cabbrev sd Sd")

vim.api.nvim_create_user_command("Sw", function()
  vim.g.strip_trailing_ws = not vim.g.strip_trailing_ws
  vim.notify("Strip whitespace: " .. (vim.g.strip_trailing_ws and "on" or "off"), vim.log.levels.INFO)
end, { desc = "Toggle remoção de whitespace" })
vim.cmd("cabbrev sw Sw")

-- Swap ESC <-> Tab
vim.keymap.set({ "i", "n", "v" }, "<Tab>", "<Esc>", { noremap = true })
vim.keymap.set({ "i", "n", "v" }, "<Esc>", "<Tab>", { noremap = true })

-- L → fim da linha
vim.keymap.set({ "n", "v" }, "L", "$", { noremap = true })

-- Keymaps principais
local map = function(m, k, v, d) vim.keymap.set(m, k, v, { desc = d, silent = true }) end

map("n", "<leader>w",  toggle_writing,               "Toggle modo escrita")
map("n", "<leader>F",  function() vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen end, "Toggle tela cheia")
map("n", "<leader>r",  toggle_reading,               "Toggle modo leitura")
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
  save_fonts()
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
-- Dashboard de abertura
local function open_dashboard()
  local months = { "jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez" }
  local function fmt_date(iso)
    local _, m, d = iso:match("(%d+)-(%d+)-(%d+)")
    return d .. " " .. (months[tonumber(m)] or m)
  end

  local recent = {}
  local seen   = {}
  local f = io.open(vim.fn.expand("~/WriteDir/sessoes.csv"), "r")
  if f then
    local skip = true
    for line in f:lines() do
      if skip then skip = false
      elseif #recent < 5 then
        local date     = line:match('^([^,]+)')
        local palavras = line:match('^[^,]+,[^,]+,[^,]+,([^,]+)')
        local doc      = line:match('"([^"]+)"')
        if doc and not seen[doc] then
          seen[doc] = true
          local short = doc:gsub(vim.fn.expand("~/WriteDir") .. "/", "")
          table.insert(recent, { date = date, palavras = tonumber(palavras) or 0, doc = short })
        end
      end
    end
    f:close()
  end

  local sep = "  " .. string.rep("─", 48)
  local lines = { "" }
  local hls   = {}   -- { line_idx (0-based), hl_group }

  local ascii_vim = {
    "  ██╗   ██╗██╗███╗   ███╗",
    "  ██║   ██║██║████╗ ████║",
    "  ██║   ██║██║██╔████╔██║",
    "  ╚██╗ ██╔╝██║██║╚██╔╝██║",
    "   ╚████╔╝ ██║██║ ╚═╝ ██║",
    "    ╚═══╝  ╚═╝╚═╝     ╚═╝",
  }
  local ascii_writer = {
    "  ██╗    ██╗██████╗ ██╗████████╗███████╗██████╗ ",
    "  ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝██╔══██╗",
    "  ██║ █╗ ██║██████╔╝██║   ██║   █████╗  ██████╔╝",
    "  ██║███╗██║██╔══██╗██║   ██║   ██╔══╝  ██╔══██╗",
    "  ╚███╔███╔╝██║  ██║██║   ██║   ███████╗██║  ██║",
    "   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝",
  }

  for _, l in ipairs(ascii_vim) do
    table.insert(hls, { #lines, "DashVim" })
    table.insert(lines, l)
  end
  table.insert(lines, "")
  for _, l in ipairs(ascii_writer) do
    table.insert(hls, { #lines, "DashWriter" })
    table.insert(lines, l)
  end
  table.insert(lines, "")
  table.insert(lines, sep)
  table.insert(lines, "")
  table.insert(hls, { #lines, "DashSection" })
  table.insert(lines, "  recentes")
  table.insert(lines, "")

  local function pad(s, w)
    return s .. string.rep(" ", math.max(0, w - vim.fn.strdisplaywidth(s)))
  end

  if #recent == 0 then
    table.insert(lines, "  nenhuma sessão registrada ainda")
  else
    for i, s in ipairs(recent) do
      local short = s.doc
      if vim.fn.strdisplaywidth(short) > 36 then
        short = "…" .. short:sub(-35)
      end
      local words = wc_format(s.palavras)
      table.insert(hls, { #lines, "DashFile" })
      table.insert(lines, string.format("  %d  %s  %s · %5s p",
        i, pad(short, 36), fmt_date(s.date), words))
    end
  end

  table.insert(lines, "")
  table.insert(lines, sep)
  table.insert(lines, "")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype   = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile  = false
  vim.api.nvim_buf_set_name(buf, "vim-writer")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_set_hl(0, "DashVim",     { fg = "#c4a7e7" })
  vim.api.nvim_set_hl(0, "DashWriter",  { fg = "#9ccfd8" })
  vim.api.nvim_set_hl(0, "DashSection", { fg = "#6e6a86", bold = true })
  vim.api.nvim_set_hl(0, "DashFile",    { fg = "#e0def4" })
  vim.api.nvim_set_hl(0, "NsStatsBold", { fg = "#e0def4", bg = "#2a273f", bold = true })
  local ns_dash = vim.api.nvim_create_namespace("dash")
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(buf, ns_dash, h[2], h[1], 0, -1)
  end

  local base = vim.fn.expand("~/WriteDir") .. "/"
  for i, s in ipairs(recent) do
    vim.keymap.set("n", tostring(i), function()
      vim.cmd("edit " .. vim.fn.fnameescape(base .. s.doc))
    end, { buffer = buf, nowait = true, silent = true })
  end

  vim.api.nvim_win_set_buf(0, buf)
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      open_dashboard()
    end
  end,
})

-- Muda o diretório local para a raiz do projeto (git) ao entrar num buffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local file = vim.fn.expand("%:p")
    if file == "" or vim.bo.buftype ~= "" then return end
    local dir = vim.fn.fnamemodify(file, ":h")
    while dir ~= "/" do
      if vim.uv.fs_stat(dir .. "/.git") then
        vim.cmd("lcd " .. vim.fn.fnameescape(dir))
        return
      end
      dir = vim.fn.fnamemodify(dir, ":h")
    end
  end,
})

local _nt_timer = vim.uv.new_timer()
vim.api.nvim_create_autocmd("CursorMoved", {
  pattern = "*",
  callback = function()
    if vim.bo.filetype ~= "nerdtree" then return end
    _nt_timer:stop()
    _nt_timer:start(250, 0, vim.schedule_wrap(function()
      local ok, path = pcall(vim.fn.eval, "g:NERDTreeFileNode.GetSelected().path.str()")
      if not ok or not path or path == "" then return end
      if vim.fn.isdirectory(path) == 1 then return end
      local nt_win = vim.api.nvim_get_current_win()
      local preview_win = nil
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= nt_win and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "nerdtree" then
          preview_win = win
          break
        end
      end
      if preview_win then
        vim.api.nvim_win_call(preview_win, function()
          if not vim.bo.modified then
            vim.cmd("silent! edit " .. vim.fn.fnameescape(path))
          end
        end)
      else
        vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(path))
        vim.cmd("wincmd p")
      end
    end))
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "nerdtree",
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf):match("vim%-writer$") then
        vim.api.nvim_buf_delete(buf, { force = true })
        break
      end
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.spell     = true
    vim.opt_local.wrap      = true
    vim.opt_local.linebreak    = true
    vim.opt_local.conceallevel = 2
    vim.cmd("PencilSoft")
    vim.cmd([[syntax match markdownHeadingMarker /^#\+\s/ conceal]])
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
  if reading_mode then reading_apply_hls() end
end

vim.api.nvim_create_autocmd("InsertEnter", { callback = apply_insert_colors })
vim.api.nvim_create_autocmd("InsertLeave", { callback = apply_normal_colors })

-- Autosave
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
  callback = function()
    if vim.bo.buftype == "" and vim.bo.modifiable and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

-- Remoção de espaços extras (inline e trailing)
vim.g.strip_trailing_ws = true
local function strip_ws()
  if not vim.g.strip_trailing_ws then return end
  if vim.bo.buftype ~= "" or not vim.bo.modifiable or vim.fn.expand("%") == "" then return end
  local view = vim.fn.winsaveview()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local changed = false
  for i, line in ipairs(lines) do
    local new = line:gsub(" +", " "):gsub("%s+$", "")
    if new ~= line then
      lines[i] = new
      changed = true
    end
  end
  if changed then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end
  vim.fn.winrestview(view)
end
vim.api.nvim_create_autocmd("InsertLeave", { callback = strip_ws })
vim.api.nvim_create_autocmd("BufWritePre", { callback = strip_ws })

-- Statusline mínima com contagem de palavras
vim.opt.laststatus = 2
vim.opt.statusline = "  %f %m%r  %=%{wordcount().words}p  %l:%c  "
