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
opt.showmode       = false     -- lualine handles this
opt.laststatus     = 3         -- global statusline
opt.cmdheight      = 1
opt.pumheight      = 12
opt.conceallevel   = 2         -- hide markdown syntax

-- Editing
opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.smartindent  = true
opt.wrap         = false
opt.breakindent  = true
opt.textwidth    = 100

-- Search
opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = true
opt.incsearch  = true

-- Files & Undo
opt.swapfile = false
opt.backup   = false
opt.undofile = true
opt.undodir  = vim.fn.expand("~/.local/share/nvim/undo")

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300
-- FIXED: must stay false — setting lazyredraw=true breaks LSP floating windows
-- and the cmdline in Neovim 0.10+ (confirmed correct as false)
opt.lazyredraw = false

-- Clipboard
opt.clipboard = "unnamedplus"

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Folding (owned entirely by nvim-ufo)
-- FIXED: was "expr" + "v:lua.vim.treesitter.foldexpr()". Having a non-empty
-- foldexpr alongside ufo's own treesitter provider caused double fold
-- computation and triggered languagetree:parse() in unsafe contexts.
-- ufo overrides foldmethod at runtime; "manual" here is just a safe default.
opt.foldmethod     = "manual"
opt.foldexpr       = ""
opt.foldlevel      = 99
opt.foldlevelstart = 99
opt.foldenable     = true

-- Misc
opt.mouse        = "a"
opt.fileencoding = "utf-8"
opt.iskeyword:append("-")                        -- treat hyphenated-words as one word
opt.formatoptions:remove({ "c", "r", "o" })     -- no auto comment on newline

-- Disable all remote-plugin language providers.
-- None of our plugins use them (pyright/ruff/eslint run as mason binaries).
-- Leaving them enabled causes neovim to spawn child nvim processes that fail
-- to create RPC sockets on macOS, producing repeated server_start warnings.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider    = 0
vim.g.loaded_perl_provider    = 0
vim.g.loaded_node_provider    = 0
