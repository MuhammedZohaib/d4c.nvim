local opt = vim.opt
local fn = vim.fn

-- Mason-managed binaries should win over system fallbacks.
vim.env.PATH = fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

if vim.env.TMUX and vim.env.TERM ~= "tmux-256color" then
  vim.env.TERM = "tmux-256color"
end

local undo_dir = fn.stdpath("state") .. "/undo"
fn.mkdir(undo_dir, "p")

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.cmdheight = 1
opt.pumheight = 12
opt.conceallevel = 2
opt.splitkeep = "screen"
opt.shortmess:append("CIWc")

pcall(function()
  opt.winborder = "rounded"
end)

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.wrap = false
opt.breakindent = true
opt.textwidth = 100
opt.list = true
opt.listchars = { tab = "> ", trail = "-", extends = ">", precedes = "<", nbsp = "+" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "-", foldsep = " ", foldclose = "+" }

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob '!.git' --glob '!node_modules' --glob '!dist' --glob '!build' --glob '!.next'"

-- Files
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.undodir = undo_dir
opt.updatetime = 200
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.autoread = true
opt.confirm = true
opt.sessionoptions = { "blank", "curdir", "folds", "help", "tabpages", "winsize", "winpos", "terminal", "localoptions" }

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Folding: nvim-ufo owns runtime folding; defaults stay safe before attach.
opt.foldmethod = "manual"
opt.foldexpr = ""
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Diff
opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- Clipboard and shell integration
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.fileencoding = "utf-8"
opt.iskeyword:append("-")
opt.formatoptions:remove({ "c", "r", "o" })

-- Ignore generated/vendor paths in native completion.
opt.wildignore:append({
  "*/.git/*",
  "*/node_modules/*",
  "*/dist/*",
  "*/build/*",
  "*/.next/*",
  "*/coverage/*",
  "*/.venv/*",
  "*/venv/*",
})

-- Disable remote-plugin providers; LSP/formatters handle these languages directly.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
