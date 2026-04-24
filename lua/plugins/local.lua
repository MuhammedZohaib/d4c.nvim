return {
  {
    name = "d4c-local-tools",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 900,
    config = function()
      require("ghost_twins").setup({
        min_lines = 4,
        max_depth = 6,
        auto_scan = false,
      })
      require("stack_tasks").setup({
        terminal_direction = "horizontal",
        terminal_size = 18,
      })
      require("route_lens").setup()
      require("env_sentinel").setup()
    end,
  },
}
