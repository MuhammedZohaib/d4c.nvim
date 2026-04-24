local map = vim.keymap.set
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Essentials
map("n", "<Esc>", "<cmd>noh<CR>", opts)
map("n", "<leader>w", "<cmd>w<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))
map("n", "<leader>q", "<cmd>q<CR>", vim.tbl_extend("force", opts, { desc = "Quit" }))
map("n", "<leader>Q", "<cmd>qa!<CR>", vim.tbl_extend("force", opts, { desc = "Force quit all" }))
map("n", "Q", "<nop>", opts)

-- Buffers
map("n", "<leader>bd", "<cmd>bd<CR>", vim.tbl_extend("force", opts, { desc = "Close buffer" }))
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
    end
  end
end, vim.tbl_extend("force", opts, { desc = "Close other buffers" }))
map("n", "<S-l>", "<cmd>bnext<CR>", opts)
map("n", "<S-h>", "<cmd>bprevious<CR>", opts)

-- Movement
map("n", "j", "gj", opts)
map("n", "k", "gk", opts)
-- <C-d> / <C-u> owned by neoscroll.nvim for smooth scroll.
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)
map("n", "<C-Up>", "<cmd>resize +2<CR>", opts)
map("n", "<C-Down>", "<cmd>resize -2<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- Lines
map("n", "<A-j>", "<cmd>m .+1<CR>==", opts)
map("n", "<A-k>", "<cmd>m .-2<CR>==", opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)
map("x", "<leader>p", [["_dP]], vim.tbl_extend("force", opts, { desc = "Paste without yanking" }))

-- Splits and explorer
map("n", "<leader>sv", "<cmd>vsplit<CR>", vim.tbl_extend("force", opts, { desc = "Vertical split" }))
map("n", "<leader>sh", "<cmd>split<CR>", vim.tbl_extend("force", opts, { desc = "Horizontal split" }))
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle explorer" }))
map("n", "<leader>o", "<cmd>Neotree focus<CR>", vim.tbl_extend("force", opts, { desc = "Focus explorer" }))

-- Search and navigation
map("n", "<leader>ff", "<cmd>FzfLua files<CR>", vim.tbl_extend("force", opts, { desc = "Find files" }))
map("n", "<leader>fg", "<cmd>FzfLua live_grep<CR>", vim.tbl_extend("force", opts, { desc = "Live grep" }))
map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", vim.tbl_extend("force", opts, { desc = "Buffers" }))
map("n", "<leader>fh", "<cmd>FzfLua helptags<CR>", vim.tbl_extend("force", opts, { desc = "Help tags" }))
map("n", "<leader>fr", "<cmd>FzfLua oldfiles<CR>", vim.tbl_extend("force", opts, { desc = "Recent files" }))
map("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", vim.tbl_extend("force", opts, { desc = "Document symbols" }))
map("n", "<leader>fS", "<cmd>FzfLua lsp_live_workspace_symbols<CR>", vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))
map("n", "<leader>fw", "<cmd>FzfLua grep_cword<CR>", vim.tbl_extend("force", opts, { desc = "Grep word" }))
map("n", "<leader>fc", "<cmd>FzfLua commands<CR>", vim.tbl_extend("force", opts, { desc = "Commands" }))
map("n", "<leader>fk", "<cmd>FzfLua keymaps<CR>", vim.tbl_extend("force", opts, { desc = "Keymaps" }))
map("n", "<leader>fd", "<cmd>FzfLua diagnostics_workspace<CR>", vim.tbl_extend("force", opts, { desc = "Workspace diagnostics" }))

-- Code actions and local analysis tools
map("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "never", timeout_ms = 2500, quiet = true })
end, vim.tbl_extend("force", opts, { desc = "Format" }))
map("n", "<leader>cF", function()
  require("conform").format({ async = false, lsp_format = "fallback", timeout_ms = 15000 })
end, vim.tbl_extend("force", opts, { desc = "Format force" }))
map("n", "<leader>ct", "<cmd>GhostTwinsScan<CR>", vim.tbl_extend("force", opts, { desc = "Ghost twins scan" }))
map("n", "<leader>cT", "<cmd>GhostTwinsClear<CR>", vim.tbl_extend("force", opts, { desc = "Ghost twins clear" }))
map("n", "<leader>cn", "<cmd>GhostTwinsNext<CR>", vim.tbl_extend("force", opts, { desc = "Next ghost twin" }))
map("n", "<leader>cp", "<cmd>GhostTwinsPrev<CR>", vim.tbl_extend("force", opts, { desc = "Previous ghost twin" }))

-- TypeScript tools
map("n", "<leader>tsi", "<cmd>TSToolsAddMissingImports<CR>", vim.tbl_extend("force", opts, { desc = "TS add imports" }))
map("n", "<leader>tso", "<cmd>TSToolsOrganizeImports<CR>", vim.tbl_extend("force", opts, { desc = "TS organize imports" }))
map("n", "<leader>tsu", "<cmd>TSToolsRemoveUnusedImports<CR>", vim.tbl_extend("force", opts, { desc = "TS remove unused" }))
map("n", "<leader>tsf", "<cmd>TSToolsFixAll<CR>", vim.tbl_extend("force", opts, { desc = "TS fix all" }))
map("n", "<leader>tsd", "<cmd>TSToolsGoToSourceDefinition<CR>", vim.tbl_extend("force", opts, { desc = "TS source definition" }))

-- Git
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", vim.tbl_extend("force", opts, { desc = "Blame line" }))
map("n", "]h", "<cmd>Gitsigns next_hunk<CR>", opts)
map("n", "[h", "<cmd>Gitsigns prev_hunk<CR>", opts)

-- Terminal and stack tasks
map("n", "<leader>tt", "<cmd>ToggleTerm direction=horizontal<CR>", vim.tbl_extend("force", opts, { desc = "Terminal horizontal" }))
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", vim.tbl_extend("force", opts, { desc = "Terminal float" }))
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", vim.tbl_extend("force", opts, { desc = "Terminal vertical" }))
map("n", "<leader>tp", "<cmd>TermExec cmd=python3 direction=horizontal<CR>", vim.tbl_extend("force", opts, { desc = "Python REPL" }))
map("n", "<leader>tn", "<cmd>TermExec cmd=node direction=horizontal<CR>", vim.tbl_extend("force", opts, { desc = "Node REPL" }))
map("n", "<leader>tr", "<cmd>StackTasks<CR>", vim.tbl_extend("force", opts, { desc = "Pick task" }))
map("n", "<leader>tl", "<cmd>StackLast<CR>", vim.tbl_extend("force", opts, { desc = "Last task" }))
map("n", "<leader>tD", "<cmd>StackRun dev<CR>", vim.tbl_extend("force", opts, { desc = "Run dev" }))
map("n", "<leader>tT", "<cmd>StackRun test<CR>", vim.tbl_extend("force", opts, { desc = "Run test" }))
map("n", "<leader>tB", "<cmd>StackRun build<CR>", vim.tbl_extend("force", opts, { desc = "Run build" }))
map("n", "<leader>tL", "<cmd>StackRun lint<CR>", vim.tbl_extend("force", opts, { desc = "Run lint" }))
map("t", "<Esc>", [[<C-\><C-n>]], opts)

-- Routes, REST, env, diagnostics
map("n", "<leader>rl", "<cmd>RouteLens<CR>", vim.tbl_extend("force", opts, { desc = "Route lens" }))
map("n", "<leader>rq", "<cmd>RouteLensQuickfix<CR>", vim.tbl_extend("force", opts, { desc = "Routes to quickfix" }))
map("n", "<leader>ee", "<cmd>EnvSentinel<CR>", vim.tbl_extend("force", opts, { desc = "Env sentinel" }))
map("n", "<leader>ec", "<cmd>EnvSentinelClear<CR>", vim.tbl_extend("force", opts, { desc = "Clear env diagnostics" }))
map("n", "<leader>xd", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Line diagnostics" }))
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", vim.tbl_extend("force", opts, { desc = "Diagnostics list" }))
map("n", "<leader>xi", "<cmd>ProjectHealth<CR>", vim.tbl_extend("force", opts, { desc = "Project health" }))
map("n", "[d", function()
  if vim.diagnostic.jump then
    vim.diagnostic.jump({ count = -1, float = true })
  else
    vim.diagnostic.goto_prev()
  end
end, opts)
map("n", "]d", function()
  if vim.diagnostic.jump then
    vim.diagnostic.jump({ count = 1, float = true })
  else
    vim.diagnostic.goto_next()
  end
end, opts)

-- Misc
map("n", "<leader>u", "<cmd>UndotreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Undo tree" }))
map("n", "<leader>z", "<cmd>ZenMode<CR>", vim.tbl_extend("force", opts, { desc = "Zen mode" }))
