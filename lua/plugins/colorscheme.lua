return {
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
    opts = {
      flavour          = "mocha",
      transparent_background = false,
      term_colors      = true,
      integrations = {
        cmp          = true,
        gitsigns     = true,
        neotree      = true,
        telescope    = { enabled = true },
        treesitter   = true,
        mason        = true,
        which_key    = true,
        bufferline   = true,
        lsp_trouble  = true,
        indent_blankline = { enabled = true },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
