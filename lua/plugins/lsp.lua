return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      ui = {
        border = "rounded",
        icons = { package_installed = "ok", package_pending = "..", package_uninstalled = "--" },
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      automatic_enable = false,
      ensure_installed = {
        "eslint",
        "html",
        "cssls",
        "tailwindcss",
        "jsonls",
        "yamlls",
        "dockerls",
        "docker_compose_language_service",
        "lua_ls",
        "bashls",
        "pyright",
        "ruff",
      },
      handlers = {
        function(_) end,
      },
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "prettierd",
        "prettier",
        "stylua",
        "shfmt",
        "shellcheck",
        "ruff",
        "hadolint",
        "markdownlint-cli2",
      },
      run_on_start = true,
      start_delay = 2500,
      debounce_hours = 24,
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.diagnostic.config({
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = ">",
          severity = { min = vim.diagnostic.severity.ERROR },
        },
        signs = {
          severity = { min = vim.diagnostic.severity.HINT },
          text = {
            [vim.diagnostic.severity.ERROR] = "E ",
            [vim.diagnostic.severity.WARN] = "W ",
            [vim.diagnostic.severity.INFO] = "I ",
            [vim.diagnostic.severity.HINT] = "H ",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          focusable = true,
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      local function with_fzf(name, fallback)
        return function()
          local ok, fzf = pcall(require, "fzf-lua")
          if ok and fzf[name] then
            return fzf[name]()
          end
          return fallback()
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("d4c_lsp_attach", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          if client and client.server_capabilities then
            client.server_capabilities.semanticTokensProvider = nil
          end

          map("gd", with_fzf("lsp_definitions", vim.lsp.buf.definition), "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", with_fzf("lsp_references", vim.lsp.buf.references), "Find references")
          map("gI", with_fzf("lsp_implementations", vim.lsp.buf.implementation), "Go to implementation")
          map("gy", with_fzf("lsp_typedefs", vim.lsp.buf.type_definition), "Go to type definition")
          map("<leader>ss", with_fzf("lsp_document_symbols", vim.lsp.buf.document_symbol), "Document symbols")
          map("<leader>sS", with_fzf("lsp_live_workspace_symbols", vim.lsp.buf.workspace_symbol), "Workspace symbols")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("K", vim.lsp.buf.hover, "Hover")
          map("gK", vim.lsp.buf.signature_help, "Signature help")

          if vim.lsp.inlay_hint then
            map("<leader>ih", function()
              local enabled = false
              local ok_enabled, result = pcall(vim.lsp.inlay_hint.is_enabled, { bufnr = event.buf })
              if ok_enabled then
                enabled = result
              else
                local ok_old, old_result = pcall(vim.lsp.inlay_hint.is_enabled, event.buf)
                enabled = ok_old and old_result or false
              end

              local ok_new = pcall(vim.lsp.inlay_hint.enable, not enabled, { bufnr = event.buf })
              if not ok_new then
                pcall(vim.lsp.inlay_hint.enable, event.buf, not enabled)
              end
            end, "Toggle inlay hints")
          end
        end,
      })

      local default = { capabilities = capabilities }
      local servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ruff = {
          init_options = {
            settings = {
              lineLength = 88,
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        eslint = {
          root_dir = util.root_pattern(
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            "eslint.config.ts",
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.json",
            "package.json"
          ),
          settings = {
            workingDirectories = { mode = "auto" },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              keyOrdering = false,
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.{yml,yaml}",
              },
            },
          },
        },
        jsonls = {},
        html = {},
        cssls = {},
        tailwindcss = {},
        dockerls = {},
        docker_compose_language_service = {},
        bashls = {},
      }

      local use_native_lsp = vim.lsp.config ~= nil and vim.lsp.enable ~= nil
      for server_name, server_opts in pairs(servers) do
        local opts = vim.tbl_deep_extend("force", {}, default, server_opts or {})
        if use_native_lsp then
          vim.lsp.config(server_name, opts)
          vim.lsp.enable(server_name)
        elseif lspconfig[server_name] then
          lspconfig[server_name].setup(opts)
        end
      end
    end,
  },

  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols" },
      { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix" },
    },
  },
}
