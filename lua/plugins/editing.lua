return {
  -- Surround text objects
  {
    "kylechui/nvim-surround",
    version = "*",
    event   = "VeryLazy",
    opts    = {},
  },

  -- Comment toggle
  {
    "numToStr/Comment.nvim",
    event = "BufReadPost",
    opts  = {},
  },

  -- Multi-cursor search/replace
  {
    "nvim-pack/nvim-spectre",
    cmd  = "Spectre",
    keys = {
      { "<leader>S",  function() require("spectre").open() end,                             desc = "Spectre (replace)" },
      { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Spectre word" },
    },
    opts = {},
  },

  -- Better f/t motions
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts  = {},
    keys  = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,             desc = "Remote Flash" },
      { "<C-s>", mode = { "c" },           function() require("flash").toggle() end,             desc = "Toggle Flash Search" },
    },
  },

  -- Which-key: keybinding popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts  = {
      preset = "modern",
      spec = {
        { "<leader>f",  group = "Find/Telescope" },
        { "<leader>l",  group = "LSP"            },
        { "<leader>g",  group = "Git"            },
        { "<leader>h",  group = "Git Hunks"      },
        { "<leader>t",  group = "Terminal/REPL"  },
        { "<leader>s",  group = "Split"          },
        { "<leader>p",  group = "Persistence"    },
        { "<leader>x",  group = "Trouble/Diag"   },
      },
    },
  },

  -- Better folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    keys = {
      { "zR", function() require("ufo").openAllFolds()  end, desc = "Open All Folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close All Folds" },
    },
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
    },
  },

  -- Highlight todo/fixme/hack comments
  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = "BufReadPost",
    opts  = {},
    keys  = {
      { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Todo Comments" },
      { "]t",  function() require("todo-comments").jump_next() end, desc = "Next Todo" },
      { "[t",  function() require("todo-comments").jump_prev() end, desc = "Prev Todo" },
    },
  },

  -- Smooth scrolling
  { "karb94/neoscroll.nvim", event = "VeryLazy", opts = { mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>" } } },

  -- Better quickfix
  { "kevinhwang91/nvim-bqf", event = "FileType qf" },

  -- Markdown preview (opens in browser)
  {
    "iamcco/markdown-preview.nvim",
    cmd   = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    ft    = { "markdown" },
    keys  = { { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview" } },
  },
}
