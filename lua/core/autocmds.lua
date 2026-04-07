-- ============================================================
-- Autocommands
-- ============================================================
local au = vim.api.nvim_create_autocmd
local ag = vim.api.nvim_create_augroup

-- Highlight yanked text
au("TextYankPost", {
	group = ag("YankHighlight", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- Remove trailing whitespace on save
au("BufWritePre", {
	group = ag("TrimWhitespace", { clear = true }),
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

-- Restore cursor position
au("BufReadPost", {
	group = ag("RestoreCursor", { clear = true }),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Auto-resize splits on terminal resize
au("VimResized", {
	group = ag("ResizeSplits", { clear = true }),
	command = "tabdo wincmd =",
})

-- Close certain windows with q
au("FileType", {
	group = ag("QuickClose", { clear = true }),
	pattern = { "help", "qf", "lspinfo", "man", "notify", "spectre_panel" },
	callback = function(event)
		vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = event.buf, silent = true })
	end,
})

-- Set filetype for common AI/ML files
au({ "BufRead", "BufNewFile" }, {
	group = ag("AIFileTypes", { clear = true }),
	pattern = { "*.ipynb" },
	command = "setfiletype json",
})

-- Python-specific settings
au("FileType", {
	group = ag("PythonSettings", { clear = true }),
	pattern = "python",
	callback = function()
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4
		vim.opt_local.colorcolumn = "88" -- Black's line length
	end,
})
