return {
	-- Formatter
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",
		opts = {
			formatters_by_ft = {
				python = { "ruff_fix", "ruff_format" }, -- ruff replaces black + isort
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
				sql = { "sql_formatter", lsp_format = "prefer" },
			},
			formatters = {
				sql_formatter = {
					command = "sql-formatter",
					args = { "--language", "postgresql" },
					stdin = true,
				},
			},
			format_on_save = {
				timeout_ms = 3000,
				lsp_fallback = true,
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
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				dockerfile = { "hadolint" },
				yaml = { "yamllint" },
				markdown = { "markdownlint" },
			}
			-- Lint on save and enter
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				callback = function()
					local ft = vim.bo.filetype
					if lint.linters_by_ft[ft] then
						lint.try_lint()
					end
				end,
			})
		end,
	},
}
