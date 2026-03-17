return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then return 18
        elseif term.direction == "vertical" then return vim.o.columns * 0.4
        end
      end,
      open_mapping    = [[<C-\>]],
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

      -- Dedicated terminal shortcuts
      local Terminal = require("toggleterm.terminal").Terminal

      -- Python REPL
      local ipython = Terminal:new({ cmd = "ipython", direction = "horizontal", hidden = true })
      vim.keymap.set("n", "<leader>tp", function() ipython:toggle() end, { desc = "IPython REPL" })

      -- Node REPL
      local node = Terminal:new({ cmd = "node", direction = "horizontal", hidden = true })
      vim.keymap.set("n", "<leader>tn", function() node:toggle() end, { desc = "Node REPL" })
    end,
  },
}
