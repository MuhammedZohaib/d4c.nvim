return {
	-- Formatter
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",
		opts = {
			formatters_by_ft = {
				python = { "ruff_fix", "ruff_format" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				lua = { "stylua" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				sql = { "sqlfmt" },
			},
			format_on_save = {
				-- FIXED: was 3000ms — reduced to 1500ms for snappier saves.
				-- Increase per-formatter only if a specific one is slow.
				timeout_ms = 1500,
				lsp_format = "fallback", -- lsp_fallback was deprecated in conform v8
			},
		},
	},

	-- Linter
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				python = { "ruff" },
				dockerfile = { "hadolint" },
				yaml = { "yamllint" },
				-- FIXED: was "markdownlint" — aligned with the mason package
				-- "markdownlint-cli2" installed via mason-tool-installer.
				markdown = { "markdownlint-cli2" },
			}
			-- JS/TS diagnostics come from eslint LSP (configured in lsp.lua).
			-- This avoids eslint_d daemon startup failures (e.g. EMFILE) that
			-- produce non-JSON output and trigger parse popups in nvim-lint.

			-- FIXED: removed InsertLeave — yamllint and markdownlint-cli2 are slow
			-- enough that linting on every insert-leave causes noticeable lag.
			-- BufWritePost + BufReadPost gives full coverage with zero typing overhead.
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = function()
					local ft = vim.bo.filetype
					if lint.linters_by_ft[ft] then
						pcall(lint.try_lint)
					end
				end,
			})
		end,
	},
}
