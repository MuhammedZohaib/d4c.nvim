# d4c.nvim

A focused Neovim config for TypeScript/JavaScript, Python, shell, Markdown, Docker, CSS, and full-stack web work.

## Stack

- Plugin manager: lazy.nvim
- Theme: gruvbox-material
- Search: fzf-lua + ripgrep
- LSP: TypeScript tools, ESLint, Pyright, Ruff, Bash, Docker, JSON, YAML, HTML, CSS, Tailwind
- Formatting: conform.nvim with Prettier/Prettierd, Ruff, Shfmt, Stylua
- Linting: shellcheck, hadolint, markdownlint-cli2
- Local tools: ghost-twins, stack-tasks, route-lens, env-sentinel

## Structure

```text
~/.config/nvim/
├── init.lua
├── lua/core/
│   ├── options.lua
│   ├── keymaps.lua
│   ├── autocmds.lua
│   ├── lazy.lua
│   └── project_health.lua
├── lua/plugins/
│   └── *.lua
├── lua/ghost_twins/
├── lua/stack_tasks/
├── lua/route_lens/
└── lua/env_sentinel/
```

## Local Plugins

- `ghost-twins.nvim`: Treesitter structural clone detection with grouped highlights.
- `stack-tasks.nvim`: project-aware task picker and runner for npm/pnpm/yarn/bun, Python, Docker, and REPLs.
- `route-lens.nvim`: API route discovery for Express/Fastify/Nest/FastAPI/Next-style routes.
- `env-sentinel.nvim`: compares `.env.example` against local env files and reports missing/duplicate keys without displaying secret values.

## Useful Keys

- `<leader>ff`: files
- `<leader>fg`: live grep
- `<leader>cf`: format
- `<leader>ct`: scan ghost twins
- `<leader>tr`: pick project task
- `<leader>rl`: find routes
- `<leader>ee`: env sentinel
- `<leader>xi`: project health dashboard
- `<leader>gg`: lazygit
- `<leader>rr`: run HTTP request in `.http` files

## External Tools

Install these manually for the best experience:

```bash
brew install ripgrep fd git node pnpm python docker shellcheck hadolint shfmt stylua lazygit
npm install -g markdownlint-cli2
python3 -m pip install --user ipython pytest ruff
```

A Nerd Font is required for dashboard icons, lualine, bufferline, and neo-tree (e.g. `brew install --cask font-jetbrains-mono-nerd-font`).

Mason also manages the configured LSP servers and formatter/linter binaries where available. After changing plugin specs, run `:Lazy sync` and `:Mason` inside Neovim.

## UI Additions

- `alpha-nvim` dashboard on blank start (`f`, `r`, `g`, `n`, `e`, `s`, `h`, `l`, `m`, `c`, `q`).
- `noice.nvim` command palette and cmdline popup with `nvim-notify`.
- `mini.animate` lightweight scroll animation only (cursor/resize disabled for speed).

## Zero-Error Verification

Run these after any change to confirm a clean state:

```vim
:checkhealth
:Lazy health
:Lazy sync
:Mason
:TSUpdate
:messages
:lua =vim.diagnostic.config()
```

A cold smoke test (no state, just load the config and exit):

```bash
nvim --headless -u ~/.config/nvim/init.lua \
  "+lua vim.defer_fn(function() vim.cmd('qa!') end, 3000)" 2>&1 | grep -iE "error|deprec|fail"
```

Expect empty output. Any line is a regression.
