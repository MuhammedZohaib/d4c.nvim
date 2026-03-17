-- ============================================================
-- Keymaps
-- ============================================================
local map            = vim.keymap.set
local opts           = { noremap = true, silent = true }

-- Leader
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- ── Essentials ─────────────────────────────────────────────
map("n", "<Esc>", "<cmd>noh<CR>", opts)     -- clear search highlight
map("n", "<leader>w", "<cmd>w<CR>", opts)   -- save
map("n", "<leader>q", "<cmd>q<CR>", opts)   -- quit
map("n", "<leader>Q", "<cmd>qa!<CR>", opts) -- force quit all
map("n", "<leader>x", "<cmd>bd<CR>", opts)  -- close buffer

-- ── Better movement ────────────────────────────────────────
map("n", "j", "gj", opts)
map("n", "k", "gk", opts)
map("n", "<C-d>", "<C-d>zz", opts) -- center after scroll
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)       -- center search results
map("n", "N", "Nzzzv", opts)

-- ── Window navigation ──────────────────────────────────────
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- ── Window resize ──────────────────────────────────────────
map("n", "<C-Up>", "<cmd>resize +2<CR>", opts)
map("n", "<C-Down>", "<cmd>resize -2<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- ── Buffers ────────────────────────────────────────────────
map("n", "<S-l>", "<cmd>bnext<CR>", opts)
map("n", "<S-h>", "<cmd>bprevious<CR>", opts)
map("n", "<leader>bo", "<cmd>%bd|e#<CR>", opts) -- close all other buffers

-- ── Lines ──────────────────────────────────────────────────
map("n", "<A-j>", "<cmd>m .+1<CR>==", opts) -- move line down
map("n", "<A-k>", "<cmd>m .-2<CR>==", opts) -- move line up
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)
map("v", "<", "<gv", opts) -- stay in visual after indent
map("v", ">", ">gv", opts)

-- ── Splits ─────────────────────────────────────────────────
map("n", "<leader>sv", "<cmd>vsplit<CR>", opts)
map("n", "<leader>sh", "<cmd>split<CR>", opts)

-- ── File explorer ──────────────────────────────────────────
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", opts)
map("n", "<leader>o", "<cmd>Neotree focus<CR>", opts)

-- ── Telescope ──────────────────────────────────────────────
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts)
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", opts)
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", opts)
map("n", "<leader>fw", "<cmd>Telescope grep_string<CR>", opts)
map("n", "<leader>fc", "<cmd>Telescope commands<CR>", opts)
map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", opts)
map("n", "<leader>fd", "<cmd>Telescope diagnostics<CR>", opts)

-- ── LSP (set in on_attach, but global fallbacks) ───────────
map("n", "<leader>lf", function() require("conform").format({ async = true }) end, opts)

-- ── Git ────────────────────────────────────────────────────
map("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<CR>", opts)
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", opts)
map("n", "]h", "<cmd>Gitsigns next_hunk<CR>", opts)
map("n", "[h", "<cmd>Gitsigns prev_hunk<CR>", opts)

-- ── Terminal ───────────────────────────────────────────────
map("n", "<leader>tt", "<cmd>ToggleTerm direction=horizontal<CR>", opts)
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", opts)
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", opts)
map("t", "<Esc>", [[<C-\><C-n>]], opts) -- exit terminal mode

-- ── Diagnostics ────────────────────────────────────────────
map("n", "<leader>dd", vim.diagnostic.open_float, opts)
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)

-- ── Misc ───────────────────────────────────────────────────
map("n", "<leader>u", "<cmd>UndotreeToggle<CR>", opts)
map("n", "<leader>z", "<cmd>ZenMode<CR>", opts)
map("x", "<leader>p", [["_dP]], opts) -- paste without overwriting register
map("n", "Q", "<nop>", opts)          -- disable Ex mode
