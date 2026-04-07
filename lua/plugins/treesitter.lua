return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build  = ":TSUpdate",
    -- FIXED: was lazy=false (forced startup load). BufReadPost defers until
    -- the first file is opened — no visible difference in practice since a file
    -- is always opened immediately, but startup time is measurably reduced.
    event  = "BufReadPost",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
      "windwp/nvim-ts-autotag",
    },
    config = function()
      local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.schedule(function()
          vim.notify(
            "nvim-treesitter API mismatch detected. Run :Lazy sync to install the pinned master branch.",
            vim.log.levels.WARN
          )
        end)
        return
      end

      ts_configs.setup({
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

          -- Required by noice.nvim for cmdline regex highlighting
          "regex",
        },

        highlight = {
          enable = true,
          -- Keep markdown stable with classic syntax highlight.
          additional_vim_regex_highlighting = { "markdown" },
          disable = { "markdown", "markdown_inline" },
        },
        indent = {
          enable = true,
          disable = { "markdown" },
        },
        -- Avoid repeated parser install attempts/noise on file open.
        auto_install = false,

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
    end,
  },
}
