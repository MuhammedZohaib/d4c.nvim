return {
  {
    "petertriho/nvim-scrollbar",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      show = true,
      show_in_active_only = false,
      set_highlights = true,
      folds = 1000,
      max_lines = false,
      throttle_ms = 80,
      handle = {
        text = " ",
        color = "#4B5263",
        cterm = nil,
        blend = 20,
        hide_if_all_visible = true,
      },
      marks = {
        Cursor = { text = " ", priority = 0 },
        Search = { text = { "=", "=" }, priority = 1, color = "#98C379" },
        Error = { text = { " ", " " }, priority = 2, color = "#E06C75" },
        Warn = { text = { " ", " " }, priority = 2, color = "#E5C07B" },
        Info = { text = { " ", " " }, priority = 2, color = "#61AFEF" },
        Hint = { text = { " ", " " }, priority = 2, color = "#56B6C2" },
        Misc = { text = { " ", " " }, priority = 1, color = "#ABB2BF" },
      },
      excluded_buftypes = { "terminal", "nofile", "prompt" },
      excluded_filetypes = {
        "help",
        "neo-tree",
        "NvimTree",
        "Trouble",
        "lazy",
        "mason",
        "notify",
        "qf",
      },
      handlers = {
        cursor = false,
        diagnostic = true,
        gitsigns = false,
        handle = true,
        search = false,
      },
    },
    config = function(_, opts)
      require("scrollbar").setup(opts)
      require("scrollbar.handlers.diagnostic").setup()
    end,
  },
}
