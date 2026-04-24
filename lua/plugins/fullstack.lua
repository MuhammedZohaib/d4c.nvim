return {
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>rr", function() require("kulala").run() end, desc = "Run HTTP request" },
      { "<leader>ra", function() require("kulala").run_all() end, desc = "Run all HTTP requests" },
      { "<leader>rp", function() require("kulala").jump_prev() end, desc = "Previous request" },
      { "<leader>rn", function() require("kulala").jump_next() end, desc = "Next request" },
    },
    opts = {
      default_view = "body",
      display_mode = "split",
      split_direction = "vertical",
    },
  },

  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufReadPost package.json", "BufNewFile package.json" },
    config = function()
      local function set_package_info_keymaps(bufnr)
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
        if name ~= "package.json" then
          return
        end

        local package_info = require("package-info")
        local map_opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "<leader>ns", package_info.show, vim.tbl_extend("force", map_opts, { desc = "Show package versions" }))
        vim.keymap.set("n", "<leader>nh", package_info.hide, vim.tbl_extend("force", map_opts, { desc = "Hide package versions" }))
        vim.keymap.set("n", "<leader>nu", package_info.update, vim.tbl_extend("force", map_opts, { desc = "Update package" }))
        vim.keymap.set("n", "<leader>nd", package_info.delete, vim.tbl_extend("force", map_opts, { desc = "Delete package" }))
        vim.keymap.set("n", "<leader>ni", package_info.install, vim.tbl_extend("force", map_opts, { desc = "Install package" }))
        vim.keymap.set("n", "<leader>nv", package_info.change_version, vim.tbl_extend("force", map_opts, { desc = "Change package version" }))
      end

      require("package-info").setup({
        autostart = false,
        hide_up_to_date = true,
        hide_unstable_versions = false,
        colors = {
          up_to_date = "#3C4048",
          outdated = "#d19a66",
        },
        icons = { enable = false },
      })

      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("PackageInfoKeymaps", { clear = true }),
        pattern = "package.json",
        callback = function(event)
          set_package_info_keymaps(event.buf)
        end,
      })

      set_package_info_keymaps(vim.api.nvim_get_current_buf())
    end,
  },

  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    opts = {
      settings = {
        separate_diagnostic_server = true,
        publish_diagnostic_on = "insert_leave",
        tsserver_max_memory = "auto",
        expose_as_code_action = { "fix_all", "add_missing_imports", "remove_unused" },
        jsx_close_tag = { enable = true, filetypes = { "javascriptreact", "typescriptreact" } },
      },
    },
  },

  {
    "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    cmd = { "AerialToggle" },
    keys = {
      { "<leader>a", "<cmd>AerialToggle<CR>", desc = "Toggle outline" },
      { "[a", "<cmd>AerialPrev<CR>", desc = "Previous symbol" },
      { "]a", "<cmd>AerialNext<CR>", desc = "Next symbol" },
      { "<leader>fo", "<cmd>AerialToggle<CR>", desc = "Outline" },
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown" },
      layout = {
        max_width = { 40, 0.25 },
        min_width = 24,
        default_direction = "right",
      },
      attach_mode = "window",
      show_guides = true,
      filter_kind = false,
      highlight_on_hover = true,
      autojump = false,
    },
  },

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
      { "<leader>hh", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
      { "<leader>hp", function() require("harpoon"):list():prev() end, desc = "Harpoon previous" },
      { "<leader>hn", function() require("harpoon"):list():next() end, desc = "Harpoon next" },
    },
    config = function()
      require("harpoon"):setup({})
    end,
  },

  {
    "echasnovski/mini.ai",
    version = "*",
    event = "VeryLazy",
    config = function()
      local ai = require("mini.ai")
      ai.setup({
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        },
      })
    end,
  },
}
