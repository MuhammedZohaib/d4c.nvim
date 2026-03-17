<div align="center">

```
 ____  _  _    ____     ____  _  _  _  _  __  __
|  _ \| || |  / ___|   |  _ \| || || || ||  \/  |
| | | | || |_| |       | | | | || || || || |\/| |
| |_| |__   _| |___    | |_| |__   _||__||_|  |_|
|____/   |_|  \____|   |____/   |_|  .__/
                                    |_|
```

# d4c.nvim

> _"Dirty Deeds Done Dirt Cheap — and this config hops between machines like Valentine crosses dimensions."_

**A modular, minimal Neovim config built to work everywhere. No cruft. No compromises.**

![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?style=flat-square&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?style=flat-square&logo=lua&logoColor=white)
![Plugin Manager](https://img.shields.io/badge/Plugin%20Manager-lazy.nvim-fb4d3d?style=flat-square)
![Theme](https://img.shields.io/badge/Theme-Catppuccin-cba6f7?style=flat-square)

</div>

---

## Structure

```
~/.config/nvim/
├── init.lua              ← Entry point. Loads the four core modules.
└── lua/
    └── core/
        ├── options.lua   ← Editor settings
        ├── keymaps.lua   ← Key bindings
        ├── autocmds.lua  ← Auto commands
        └── lazy.lua      ← Plugin manager bootstrap + plugin specs
```

`init.lua` does one thing — require the four core modules in order:

```lua
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.lazy")   -- Plugin manager bootstrap
```

---

## Requirements

| Dependency                                | Purpose                    |
| ----------------------------------------- | -------------------------- |
| Neovim ≥ 0.10                             | Required                   |
| Git                                       | Plugin installation        |
| A [Nerd Font](https://www.nerdfonts.com/) | Icons throughout the UI    |
| `ripgrep`                                 | Telescope live grep        |
| `node` + `npm`                            | Some LSP servers via Mason |
| `ipython`                                 | Python REPL (`<leader>tp`) |
| `yarn`                                    | Markdown preview           |

Install the two non-Mason tools:

```bash
# Python REPL
python3 -m pip install --user ipython

# Markdown preview
brew install yarn
```

Everything else — formatters, linters, LSP servers — is handled automatically by **Mason** on first launch.

---

## Installation

```bash
# Back up existing config if needed
mv ~/.config/nvim ~/.config/nvim.bak

# Clone the repo
git clone https://github.com/MuhammedZohaib/d4c.nvim ~/.config/nvim

# Launch Neovim — lazy.nvim bootstraps itself and installs all plugins
nvim
```

On first open, `lazy.nvim` will self-install and pull all plugins. Mason will then auto-install the configured LSP servers, formatters, and linters.

---

## Plugins

### UI & Aesthetics

| Plugin                  | Role                                      |
| ----------------------- | ----------------------------------------- |
| `catppuccin`            | Colorscheme                               |
| `lualine.nvim`          | Statusline                                |
| `bufferline.nvim`       | Buffer tabs                               |
| `dashboard-nvim`        | Startup screen                            |
| `noice.nvim`            | Replaces cmdline, messages, and popupmenu |
| `nvim-notify`           | Notification UI                           |
| `dressing.nvim`         | Improved `vim.ui.select` / `vim.ui.input` |
| `indent-blankline.nvim` | Indent guides                             |
| `nvim-colorizer.lua`    | Inline hex color preview                  |
| `nvim-web-devicons`     | File type icons                           |
| `neoscroll.nvim`        | Smooth scrolling                          |

### Navigation & Search

| Plugin                      | Role                         |
| --------------------------- | ---------------------------- |
| `telescope.nvim`            | Fuzzy finder                 |
| `telescope-fzf-native.nvim` | FZF sorter for Telescope     |
| `telescope-ui-select.nvim`  | Telescope as `vim.ui.select` |
| `neo-tree.nvim`             | File explorer                |
| `flash.nvim`                | Jump/search motions          |
| `nvim-spectre`              | Project-wide find & replace  |
| `nvim-bqf`                  | Better quickfix list         |

### LSP & Completion

| Plugin                      | Role                                  |
| --------------------------- | ------------------------------------- |
| `nvim-lspconfig`            | LSP client configuration              |
| `mason.nvim`                | LSP/formatter/linter installer        |
| `mason-lspconfig.nvim`      | Mason ↔ lspconfig bridge              |
| `mason-tool-installer.nvim` | Auto-installs tools on startup        |
| `lspsaga.nvim`              | Enhanced LSP UI (hover, rename, etc.) |
| `lazydev.nvim`              | Lua API completions for Neovim config |
| `lspkind.nvim`              | VSCode-style pictograms in completion |
| `nvim-cmp`                  | Completion engine                     |
| `cmp-nvim-lsp`              | LSP source                            |
| `cmp-buffer`                | Buffer words source                   |
| `cmp-path`                  | Filesystem path source                |
| `cmp-cmdline`               | Cmdline source                        |
| `cmp_luasnip`               | Snippet source                        |
| `LuaSnip`                   | Snippet engine                        |
| `friendly-snippets`         | Snippet collection                    |

### Treesitter

| Plugin                        | Role                                 |
| ----------------------------- | ------------------------------------ |
| `nvim-treesitter`             | Syntax highlighting & parsing        |
| `nvim-treesitter-context`     | Sticky function/class context at top |
| `nvim-treesitter-textobjects` | Select/move by syntax node           |
| `nvim-ts-autotag`             | Auto close/rename HTML tags          |

### Formatting & Linting

| Plugin         | Role             |
| -------------- | ---------------- |
| `conform.nvim` | Formatter runner |
| `nvim-lint`    | Linter runner    |

### Git

| Plugin              | Role                                   |
| ------------------- | -------------------------------------- |
| `gitsigns.nvim`     | Git signs in the gutter                |
| `lazygit.nvim`      | LazyGit in a terminal float            |
| `git-conflict.nvim` | Merge conflict highlights & resolution |

### Editing

| Plugin               | Role                                   |
| -------------------- | -------------------------------------- |
| `nvim-autopairs`     | Auto-close brackets/quotes             |
| `nvim-surround`      | Add/change/delete surroundings         |
| `Comment.nvim`       | Toggle comments                        |
| `nvim-ufo`           | Folding with LSP/Treesitter providers  |
| `todo-comments.nvim` | Highlight & search `TODO`, `FIX`, etc. |
| `undotree`           | Visual undo history                    |
| `zen-mode.nvim`      | Distraction-free writing               |

### Terminal & Sessions

| Plugin             | Role                       |
| ------------------ | -------------------------- |
| `toggleterm.nvim`  | Persistent terminal panels |
| `persistence.nvim` | Auto session save/restore  |

### Utilities

| Plugin                  | Role                             |
| ----------------------- | -------------------------------- |
| `which-key.nvim`        | Keybind popup                    |
| `trouble.nvim`          | Diagnostics list panel           |
| `markdown-preview.nvim` | Live Markdown preview in browser |
| `promise-async`         | Async utility (used by nvim-ufo) |
| `plenary.nvim`          | Lua utility library              |
| `nui.nvim`              | UI component library             |

---

## Environment

Most tools are auto-managed. See [`ENV_SETUP.md`](./ENV_SETUP.md) for the two external dependencies and notes on optional AI plugin setup.

---

<div align="center">

_"The thing about D4C is — it works in every world."_

</div>
