return {
  -- Mason: LSP/DAP/linter/formatter installer
  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "pyright",
        "ts_ls",
        "eslint",
        "lua_ls",
        "jsonls",
        "yamlls",
        "html",
        "cssls",
        "tailwindcss",
        "dockerls",
        "docker_compose_language_service",
        "bashls",
        "marksman",
        "graphql",
        "sqlls",
      },
    },
  },

  -- Ensure non-LSP tools are installed too (formatters/linters)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        "ruff",
        "sqlfmt",
        "prettier",
        "eslint_d",
        "hadolint",
        "yamllint",
        "markdownlint",
      },
      run_on_start = true,
      start_delay = 3000,
      debounce_hours = 12,
    },
  },

  -- Main LSP config
  {
    "neovim/nvim-lspconfig",
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
      local cmp_lsp = require("cmp_nvim_lsp")

      local capabilities = cmp_lsp.default_capabilities()

      -- Diagnostic display
      vim.diagnostic.config({
        virtual_text = { prefix = "●", source = "if_many" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- Sign icons
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Shared on_attach
      local on_attach = function(client, bufnr)
        local bmap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        bmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        bmap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
        bmap("n", "gr", vim.lsp.buf.references, "References")
        bmap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
        bmap("n", "gy", vim.lsp.buf.type_definition, "Type Definition")
        bmap("n", "K", vim.lsp.buf.hover, "Hover Docs")
        bmap("n", "<C-s>", vim.lsp.buf.signature_help, "Signature Help")
        bmap("n", "<leader>lr", vim.lsp.buf.rename, "Rename Symbol")
        bmap({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code Action")
        bmap("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP Info")
      end

      -- Shared defaults for all servers
      local default = { capabilities = capabilities, on_attach = on_attach }

      -- Server-specific settings
      local servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode       = "standard",
                autoSearchPaths        = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ts_ls = {
          settings = {
            typescript = { inlayHints = { includeInlayParameterNameHints = "all" } },
            javascript = { inlayHints = { includeInlayParameterNameHints = "all" } },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace   = { checkThirdParty = false },
              telemetry   = { enable = false },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              keyOrdering = false,
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] =
                "docker-compose*.{yml,yaml}",
              },
            },
          },
        },
        eslint = {},
        jsonls = {},
        html = {},
        cssls = {},
        tailwindcss = {},
        dockerls = {},
        docker_compose_language_service = {},
        bashls = {},
        marksman = {},
        graphql = {},
        sqlls = {},
      }

      local setup_server = function(server_name, server_opts)
        local opts = vim.tbl_deep_extend("force", {}, default, server_opts or {})
        if vim.lsp.config and vim.lsp.enable then
          vim.lsp.config(server_name, opts)
          vim.lsp.enable(server_name)
          return
        end
        if lspconfig[server_name] then
          lspconfig[server_name].setup(opts)
        end
      end

      for server_name, server_opts in pairs(servers) do
        setup_server(server_name, server_opts)
      end
    end,
  },

  -- Better LSP UI
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-treesitter/nvim-treesitter" },
    opts = {
      lightbulb = { enable = false },
      symbol_in_winbar = { enable = true },
      ui = { border = "rounded" },
    },
    init = function()
      local map = vim.keymap.set
      map("n", "gh", "<cmd>Lspsaga finder<CR>", { silent = true, desc = "LSP Finder" })
      map("n", "<leader>lo", "<cmd>Lspsaga outline<CR>", { silent = true, desc = "Outline" })
      map("n", "<leader>lp", "<cmd>Lspsaga peek_definition<CR>", { silent = true, desc = "Peek Definition" })
      map("n", "<leader>lt", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true, desc = "Peek Type" })
    end,
  },

  -- Trouble: pretty diagnostics list
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",                        desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",           desc = "Buffer Diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>",                desc = "Symbols" },
      { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",                             desc = "Quickfix" },
    },
  },
}
