return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		opts = {
			close_if_last_window = true,
			window = {
				width = 35,
				position = "left",
				mappings = {
					["<space>"] = false,
					["l"] = "open",
					["h"] = "close_node",
					["<CR>"] = "open",
					["/"] = "fuzzy_finder",
				},
			},
			filesystem = {
				filtered_items = {
					visible = true, -- show hidden files dimmed
					hide_dotfiles = false,
					hide_gitignored = true,
				},
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true,
			},
			default_component_configs = {
				git_status = {
					symbols = {
						added = "",
						modified = "",
						deleted = "✖",
						renamed = "➜",
						untracked = "?",
						ignored = "◌",
						unstaged = "",
						staged = "✓",
						conflict = "",
					},
				},
			},
		},
	},
}
