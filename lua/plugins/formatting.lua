return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = function()
      local uv = vim.uv or vim.loop
      local util = require("conform.util")
      local prettier_roots = {
        "prettier.config.js",
        "prettier.config.cjs",
        "prettier.config.mjs",
        "prettier.config.ts",
        ".prettierrc",
        ".prettierrc.json",
        ".prettierrc.yaml",
        ".prettierrc.yml",
        ".prettierrc.js",
        ".prettierrc.cjs",
        ".prettierrc.mjs",
        "package.json",
        ".git",
      }
      local web_formatter = vim.fn.executable("prettierd") == 1 and "prettierd" or "prettier"
      local max_format_size = 512 * 1024
      local max_format_lines = 6000
      local never_lsp = {
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
        json = true,
        jsonc = true,
        css = true,
        scss = true,
        html = true,
        markdown = true,
        yaml = true,
        python = true,
      }

      local function is_large_buffer(bufnr, name)
        local ok, stat = pcall(uv.fs_stat, name)
        if ok and stat and stat.size and stat.size > max_format_size then
          return true
        end
        return vim.api.nvim_buf_line_count(bufnr) > max_format_lines
      end

      local function should_skip_format(bufnr)
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name == "" or name:find("/node_modules/", 1, true) or name:find("/.git/", 1, true) then
          return true
        end
        if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
          return true
        end
        return is_large_buffer(bufnr, name)
      end

      return {
        format_on_save = function(bufnr)
          if should_skip_format(bufnr) then
            return
          end

          local ft = vim.bo[bufnr].filetype
          return {
            timeout_ms = 2500,
            lsp_format = never_lsp[ft] and "never" or "fallback",
            quiet = true,
          }
        end,
        formatters = {
          prettierd = {
            condition = function()
              return vim.fn.executable("prettierd") == 1
            end,
            cwd = util.root_file(prettier_roots),
            require_cwd = true,
          },
          prettier = {
            condition = function()
              return vim.fn.executable("prettierd") == 0 and vim.fn.executable("prettier") == 1
            end,
            cwd = util.root_file(prettier_roots),
            require_cwd = true,
          },
        },
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = { web_formatter },
          typescript = { web_formatter },
          javascriptreact = { web_formatter },
          typescriptreact = { web_formatter },
          json = { web_formatter },
          jsonc = { web_formatter },
          css = { web_formatter },
          scss = { web_formatter },
          sass = { web_formatter },
          html = { web_formatter },
          markdown = { web_formatter },
          yaml = { web_formatter },
          python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
          sh = { "shfmt" },
          bash = { "shfmt" },
          zsh = { "shfmt" },
          ["_"] = { "trim_whitespace" },
        },
      }
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
        dockerfile = { "hadolint" },
        markdown = { "markdownlint-cli2" },
      }

      local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = group,
        callback = function()
          local ft = vim.bo.filetype
          if lint.linters_by_ft[ft] then
            pcall(lint.try_lint)
          end
        end,
      })
    end,
  },
}
