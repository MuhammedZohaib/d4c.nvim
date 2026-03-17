return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- keep legacy config API
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
      "nvim-treesitter/nvim-treesitter-context",
      "windwp/nvim-ts-autotag",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          -- Web
          "html", "css", "javascript", "typescript", "tsx", "json", "jsonc",

          -- Python / ML
          "python", "toml",

          -- Config / DevOps
          "yaml", "dockerfile", "terraform", "hcl", "bash", "make",

          -- Markup / Docs
          "markdown", "markdown_inline", "rst",

          -- Languages
          "lua", "go", "rust", "sql",

          -- Neovim
          "vim", "vimdoc", "query",
        },

        highlight = { enable = true },
        indent = { enable = true },
        auto_install = true,

        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
          },
        },
      })

      require("nvim-ts-autotag").setup()

      require("treesitter-context").setup({
        enable = true,
        max_lines = 4,
      })
    end,
  },
}
