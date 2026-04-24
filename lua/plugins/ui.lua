return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "neo-tree" } },
      },
      sections = {
        lualine_a = { { "mode", fmt = function(str) return " " .. str end } },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", { "filetype", icon_only = true } },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "center" },
        },
      },
    },
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    main = "ibl",
    opts = {
      indent = { char = "|" },
      scope = { enabled = true, show_start = false },
      exclude = {
        filetypes = { "help", "lazy", "mason", "neo-tree", "notify", "qf", "terminal" },
      },
    },
  },

  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    opts = {
      render = "compact",
      stages = "static",
      timeout = 1800,
      max_width = 72,
    },
    config = function(_, opts)
      require("notify").setup(opts)
      vim.notify = require("notify")
    end,
  },

  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = { border = "rounded" },
      select = { backend = { "fzf_lua", "builtin" } },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>ps", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>pl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>pd", function() require("persistence").stop() end, desc = "Stop session save" },
    },
  },

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = { window = { width = 0.86 } },
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },

  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        [[                                                         ]],
        [[  ██████╗ ██╗  ██╗ ██████╗    ███╗   ██╗██╗   ██╗██╗███╗ ███╗ ]],
        [[  ██╔══██╗██║  ██║██╔════╝    ████╗  ██║██║   ██║██║████╗████║ ]],
        [[  ██║  ██║███████║██║         ██╔██╗ ██║██║   ██║██║██╔████╔██║ ]],
        [[  ██║  ██║╚════██║██║         ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║ ]],
        [[  ██████╔╝     ██║╚██████╗    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║ ]],
        [[  ╚═════╝      ╚═╝ ╚═════╝    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ ]],
        [[                                                         ]],
        [[              Full-stack editor, crafted to ship.         ]],
        [[                                                         ]],
      }

      dashboard.section.buttons.val = {
        dashboard.button("f", "   Find file",          "<cmd>FzfLua files<CR>"),
        dashboard.button("r", "   Recent files",       "<cmd>FzfLua oldfiles<CR>"),
        dashboard.button("g", "   Live grep",          "<cmd>FzfLua live_grep<CR>"),
        dashboard.button("n", "   New file",           "<cmd>enew<CR>"),
        dashboard.button("e", "   Explorer",           "<cmd>Neotree toggle<CR>"),
        dashboard.button("s", "   Restore session",    "<cmd>lua require('persistence').load()<CR>"),
        dashboard.button("h", "   Project health",     "<cmd>ProjectHealth<CR>"),
        dashboard.button("l", "󰒲   Lazy",                "<cmd>Lazy<CR>"),
        dashboard.button("m", "   Mason",               "<cmd>Mason<CR>"),
        dashboard.button("c", "   Config",             "<cmd>edit ~/.config/nvim/init.lua<CR>"),
        dashboard.button("q", "   Quit",               "<cmd>qa<CR>"),
      }

      local function footer()
        local ok, lazy = pcall(require, "lazy")
        local count = ok and lazy.stats and lazy.stats().count or 0
        local ms = ok and lazy.stats and math.floor((lazy.stats().startuptime or 0) + 0.5) or 0
        return string.format("  %d plugins loaded in %d ms", count, ms)
      end

      dashboard.section.header.opts.hl = "Keyword"
      dashboard.section.buttons.opts.hl = "Function"
      dashboard.section.footer.opts.hl = "Comment"
      dashboard.opts.layout[1].val = 2

      alpha.setup(dashboard.opts)

      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "LazyVimStarted",
        callback = function()
          dashboard.section.footer.val = footer()
          pcall(vim.cmd, "AlphaRedraw")
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "AlphaReady",
        callback = function()
          dashboard.section.footer.val = footer()
          pcall(vim.cmd, "AlphaRedraw")
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "alpha",
        callback = function()
          vim.opt_local.cursorline = false
          vim.opt_local.foldenable = false
          vim.opt_local.signcolumn = "no"
        end,
      })
    end,
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        signature = { enabled = false },
        hover = { enabled = false },
      },
      cmdline = {
        view = "cmdline_popup",
        format = {
          cmdline = { pattern = "^:", icon = "", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
        },
      },
      messages = {
        enabled = true,
        view_search = false,
      },
      popupmenu = { enabled = true, backend = "nui" },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      routes = {
        {
          filter = { event = "msg_show", any = {
            { find = "written" },
            { find = "%d+L, %d+B" },
            { find = "%d+ changes?;" },
            { find = "%-%-No lines in buffer%-%-" },
          } },
          opts = { skip = true },
        },
      },
    },
  },

  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    config = function()
      local neoscroll = require("neoscroll")
      neoscroll.setup({
        mappings = {}, -- declare below for full control
        hide_cursor = true,
        stop_eof = true,
        respect_scrolloff = false,
        cursor_scrolls_alongside = true,
        easing_function = "sine",
        pre_hook = nil,
        post_hook = nil,
        performance_mode = false,
      })

      local keymap = {
        ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 160 }) end,
        ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 160 }) end,
        ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 350 }) end,
        ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 350 }) end,
        ["<C-y>"] = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 80 }) end,
        ["<C-e>"] = function() neoscroll.scroll(0.1,  { move_cursor = false, duration = 80 }) end,
        ["zt"]    = function() neoscroll.zt({ half_win_duration = 180 }) end,
        ["zz"]    = function() neoscroll.zz({ half_win_duration = 180 }) end,
        ["zb"]    = function() neoscroll.zb({ half_win_duration = 180 }) end,
      }
      for k, fn in pairs(keymap) do
        vim.keymap.set({ "n", "v", "x" }, k, fn, { silent = true, desc = "Smooth scroll " .. k })
      end
    end,
  },

  {
    "NvChad/nvim-colorizer.lua",
    ft = {
      "css",
      "scss",
      "sass",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "html",
      "json",
      "jsonc",
      "yaml",
      "markdown",
    },
    opts = {
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        names = false,
        css = true,
        tailwind = "both",
      },
    },
  },
}
