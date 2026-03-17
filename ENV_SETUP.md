# Optional Environment Setup

This config does not currently include an AI plugin file, so no AI env vars are required by default.

## First run inside Neovim

```vim
:Lazy sync
:MasonToolsInstall
:TSUpdate
:checkhealth
```

## External tools used by this config

Most formatters/linters are auto-managed by Mason + mason-tool-installer.
These tools are still expected from your system:

```bash
# Python REPL for <leader>tp
python3 -m pip install --user ipython

# Neovim Python provider (:checkhealth vim.provider)
python3 -m pip install --user pynvim

# Markdown preview dependency
brew install yarn
```
