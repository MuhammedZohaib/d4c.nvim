return {
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			winopts = {
				preview = {
					layout = "horizontal",
					horizontal = "right:55%",
				},
			},
			files = {
				cwd_prompt = false,
			},
			grep = {
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git' --glob '!node_modules' --glob '!dist' --glob '!build' --glob '!.next'",
			},
		},
	},
}
