<div align="center">

# ✦ d4c.nvim

**Dirty Deeds Done Dirt Cheap.**
_A modular Neovim config that works in every dimension._

[![Neovim](https://img.shields.io/badge/nvim-0.10+-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/lua-5.1-2C2D72?style=flat-square&logo=lua&logoColor=white)](https://lua.org)
[![lazy.nvim](https://img.shields.io/badge/plugin_manager-lazy.nvim-fb4d3d?style=flat-square)](https://github.com/folke/lazy.nvim)
[![catppuccin](https://img.shields.io/badge/theme-catppuccin-cba6f7?style=flat-square)](https://github.com/catppuccin/nvim)

</div>

---

## Structure

```
~/.config/nvim/
├── init.lua          ← loads the four core modules
└── lua/core/
    ├── options.lua   ← editor settings
    ├── keymaps.lua   ← key bindings
    ├── autocmds.lua  ← autocommands
    └── lazy.lua      ← plugin bootstrap & specs
```

---

## Install

```bash
# back up if needed
mv ~/.config/nvim ~/.config/nvim.bak

# clone
git clone https://github.com/MuhammedZohaib/d4c.nvim ~/.config/nvim

# open nvim — lazy.nvim self-installs, then Mason handles the rest
nvim
```

**Hard deps** — install these manually, everything else is auto-managed by Mason:

```bash
python3 -m pip install --user ipython  # python REPL  (<leader>tp)
brew install yarn                       # markdown preview
```

Also make sure you have: `git`, `ripgrep`, `node/npm`, and a [Nerd Font](https://www.nerdfonts.com/).

---

## Plugins

**57 plugins** managed by `lazy.nvim`, grouped by what they do:

`catppuccin` · `lualine` · `bufferline` · `dashboard-nvim` · `noice.nvim` · `nvim-notify` · `dressing.nvim` · `indent-blankline` · `nvim-colorizer`

`telescope.nvim` · `telescope-fzf-native` · `neo-tree.nvim` · `flash.nvim` · `nvim-spectre` · `nvim-bqf`

`nvim-lspconfig` · `mason.nvim` · `mason-lspconfig` · `lspsaga.nvim` · `nvim-cmp` · `LuaSnip` · `friendly-snippets` · `lspkind`

`nvim-treesitter` · `treesitter-context` · `treesitter-textobjects` · `nvim-ts-autotag`

`conform.nvim` · `nvim-lint` · `gitsigns.nvim` · `lazygit.nvim` · `git-conflict.nvim`

`nvim-autopairs` · `nvim-surround` · `Comment.nvim` · `nvim-ufo` · `todo-comments` · `undotree` · `zen-mode.nvim` · `toggleterm.nvim` · `persistence.nvim` · `which-key.nvim` · `trouble.nvim` · `markdown-preview.nvim`

---

<div align="center">

_"The thing about D4C — it works in every world."_

</div>
