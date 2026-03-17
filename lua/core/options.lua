-- ============================================================
-- Options
-- ============================================================
local opt = vim.opt

-- UI
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
opt.signcolumn     = "yes"
opt.colorcolumn    = "100"
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.termguicolors  = true
opt.showmode       = false      -- lualine handles this
opt.laststatus     = 3          -- global statusline
opt.cmdheight      = 1
opt.pumheight      = 12
opt.conceallevel   = 2          -- hide markdown syntax

-- Editing
opt.expandtab      = true
opt.shiftwidth     = 2
opt.tabstop        = 2
opt.softtabstop    = 2
opt.smartindent    = true
opt.wrap           = false
opt.breakindent    = true
opt.textwidth      = 100

-- Search
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true
opt.incsearch      = true

-- Files & Undo
opt.swapfile       = false
opt.backup         = false
opt.undofile       = true
opt.undodir        = vim.fn.expand("~/.local/share/nvim/undo")

-- Splits
opt.splitright     = true
opt.splitbelow     = true

-- Performance
opt.updatetime     = 200
opt.timeoutlen     = 300
opt.lazyredraw     = false

-- Clipboard
opt.clipboard      = "unnamedplus"   -- sync with system clipboard

-- Completion
opt.completeopt    = { "menu", "menuone", "noselect" }

-- Folding (via treesitter)
opt.foldmethod     = "expr"
opt.foldexpr       = "nvim_treesitter#foldexpr()"
opt.foldlevel      = 99             -- open all folds by default

-- Misc
opt.mouse          = "a"
opt.fileencoding   = "utf-8"
opt.iskeyword:append("-")           -- treat hyphenated-words as one word
opt.formatoptions:remove({ "c", "r", "o" })  -- no auto comment on newline

-- Python provider (use uv-managed python)
vim.g.python3_host_prog = vim.fn.trim(vim.fn.system("uv python find 3.12 2>/dev/null || which python3"))
