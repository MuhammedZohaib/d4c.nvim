return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd = { "ToggleTerm", "TermExec" },
		opts = {
			size = function(term)
				if term.direction == "horizontal" then return 18
				elseif term.direction == "vertical" then return vim.o.columns * 0.4
				end
			end,
			-- FIXED: removed open_mapping = [[<C-\>]].
			-- The global open_mapping swallows <C-\><C-n> when typed quickly in
			-- terminal mode, trapping the user. All toggle bindings are explicit:
			-- <leader>tt/tf/tv (keymaps.lua). Terminal escape is <Esc> → <C-\><C-n>
			-- also in keymaps.lua — that single binding is the sole escape route.
			hide_numbers    = true,
			shade_terminals = true,
			shading_factor  = 2,
			start_in_insert = true,
			persist_size    = true,
			direction       = "horizontal",
			close_on_exit   = true,
			shell           = vim.o.shell,
			float_opts = {
				border   = "curved",
				winblend = 8,
			},
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)

			local Terminal = require("toggleterm.terminal").Terminal

			-- Python REPL
			local ipython_cmd
			if vim.fn.executable("ipython") == 1 then
				ipython_cmd = "ipython"
			elseif vim.fn.executable("python3") == 1 then
				ipython_cmd = "python3 -m IPython"
			else
				ipython_cmd = "python"
			end
			local ipython = Terminal:new({ cmd = ipython_cmd, direction = "horizontal", hidden = true })
			vim.keymap.set("n", "<leader>tp", function() ipython:toggle() end, { desc = "IPython REPL" })

			-- Node REPL
			local node = Terminal:new({ cmd = "node", direction = "horizontal", hidden = true })
			vim.keymap.set("n", "<leader>tn", function() node:toggle() end, { desc = "Node REPL" })
		end,
	},
}
