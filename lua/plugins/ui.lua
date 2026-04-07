return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus      = true,
        section_separators   = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { { "mode", fmt = function(str) return " " .. str end } },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          { "encoding" },
          { "fileformat" },
          { "filetype", icon_only = true },
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- Buffer tabs
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    opts = {
      options = {
        diagnostics          = "nvim_lsp",
        always_show_bufferline = false,
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "center" },
        },
      },
    },
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope  = { enabled = true, show_start = false },
    },
  },

  -- Dashboard
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "doom",
      config = {
        header = {
          "",
          "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
          "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
          "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
          "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
          "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
          "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
          "",
        },
        center = {
          { icon = "  ", desc = "Find File     ", key = "f", action = "FzfLua files"         },
          { icon = "  ", desc = "Recent Files  ", key = "r", action = "FzfLua oldfiles"      },
          { icon = "  ", desc = "Grep Text     ", key = "g", action = "FzfLua live_grep"     },
          { icon = "  ", desc = "Config        ", key = "c", action = "e $MYVIMRC"           },
          { icon = "  ", desc = "Lazy          ", key = "l", action = "Lazy"                 },
          { icon = "  ", desc = "Quit          ", key = "q", action = "qa"                   },
        },
        footer = { "", "  Ready to build something great." },
      },
    },
  },

  -- Notifications
  {
    "rcarriga/nvim-notify",
    opts = {
      render    = "compact",
      -- FIXED: was "fade" — fade adds animation overhead on every notification.
      -- "static" renders instantly with zero animation cost.
      stages    = "static",
      timeout   = 2000,
      max_width = 60,
    },
    config = function(_, opts)
      require("notify").setup(opts)
      vim.notify = require("notify")
    end,
  },

  -- Better UI for input/select
  {
    "stevearc/dressing.nvim",
    opts = {},
  },

  -- Modern command line / message UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        progress  = { enabled = true },
        -- lspsaga owns hover and signature — keep noice out of those paths.
        -- Confirmed intentional: :checkhealth noice will still warn about
        -- hover/signature not being handled by Noice; that's expected.
        signature = { enabled = false },
        hover     = { enabled = false },
        -- Override markdown rendering utilities so noice can style LSP
        -- documentation (e.g. jsonls, pyright hover docs) with its own
        -- prettier markdown renderer even when hover UI is lspsaga's.
        -- Fixes the two :checkhealth noice warnings about these functions.
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"]                = true,
        },
      },
      presets = {
        bottom_search        = true,
        command_palette      = true,
        long_message_to_split = true,
        inc_rename           = false,
      },
      routes = {
        -- Suppress "written" / "x lines" file-save messages
        { filter = { event = "msg_show", kind = "", find = "written" },   opts = { skip = true } },
        { filter = { event = "msg_show", kind = "", find = "fewer lines" }, opts = { skip = true } },
        { filter = { event = "msg_show", kind = "", find = "more lines" },  opts = { skip = true } },
        -- Suppress search-count "x/y" messages that flash on n/N
        { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
      },
    },
  },

  -- Restore previous sessions
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>ps", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>pl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>pd", function() require("persistence").stop() end, desc = "Stop Session Save" },
    },
  },

  -- Zen mode
  {
    "folke/zen-mode.nvim",
    cmd  = "ZenMode",
    opts = { window = { width = 0.85 } },
  },

  -- Undo tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },

  -- Colorize hex/rgb codes
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPre",
    opts  = {
      user_default_options = {
        RGB      = true,
        RRGGBB   = true,
        names    = false,   -- skip named colors ("Blue") — too noisy
        css      = true,
        tailwind = "both",
      },
    },
  },
}
