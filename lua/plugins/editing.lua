return {
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  {
    "numToStr/Comment.nvim",
    event = "BufReadPost",
    opts = {},
  },

  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    keys = {
      { "<leader>S", function() require("spectre").open() end, desc = "Replace in project" },
      { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Replace word" },
    },
    opts = {},
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = { enabled = true },
        search = { enabled = true },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "<C-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        { "<leader>b", group = "Buffers" },
        { "<leader>c", group = "Code" },
        { "<leader>e", group = "Env/Explorer" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Harpoon" },
        { "<leader>m", group = "Markdown" },
        { "<leader>n", group = "Packages" },
        { "<leader>p", group = "Persistence/Paste" },
        { "<leader>r", group = "Routes/REST" },
        { "<leader>s", group = "Splits/Search" },
        { "<leader>t", group = "Terminal/Tasks/TypeScript" },
        { "<leader>ts", group = "TypeScript" },
        { "<leader>x", group = "Diagnostics" },
      },
    },
  },

  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    init = function()
      vim.o.foldmethod = "manual"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    },
    opts = {
      provider_selector = function(_, filetype)
        if filetype == "markdown" then
          return { "indent" }
        end
        return { "treesitter", "indent" }
      end,
    },
  },

  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = "BufReadPost",
    opts = {},
    keys = {
      { "<leader>ft", "<cmd>TodoFzfLua<CR>", desc = "Todo comments" },
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo" },
    },
  },

  { "kevinhwang91/nvim-bqf", event = "FileType qf" },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    ft = { "markdown" },
    keys = { { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown preview" } },
  },
}
