return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
        globalstatus      = true,
        section_separators   = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { { "mode", icon = "" } },
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
          { icon = "  ", desc = "Find File     ", key = "f", action = "Telescope find_files" },
          { icon = "  ", desc = "Recent Files  ", key = "r", action = "Telescope oldfiles"   },
          { icon = "  ", desc = "Grep Text     ", key = "g", action = "Telescope live_grep"  },
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
      render   = "compact",
      stages   = "fade",
      timeout  = 2000,
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
    opts  = {},
  },
}
