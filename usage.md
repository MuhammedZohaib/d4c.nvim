Leader = **Space**. Localleader = **\\**.

## Files & Search (fzf-lua)

| Key          | Action                                   |
| ------------ | ---------------------------------------- |
| `<leader>ff` | Find files                               |
| `<leader>fg` | Live grep (search text in project)       |
| `<leader>fb` | Switch buffer                            |
| `<leader>fh` | Help tags                                |
| `<leader>fr` | Recent files                             |
| `<leader>fw` | Grep word under cursor                   |
| `<leader>fc` | All commands                             |
| `<leader>fk` | All keymaps (forgot a binding? hit this) |
| `<leader>fd` | Workspace diagnostics                    |
| `<leader>fs` | Document symbols                         |
| `<leader>fS` | Workspace symbols                        |
| `<leader>ft` | Todo comments                            |
| `<leader>fo` | Code outline (aerial)                    |
| `<leader>S`  | Spectre: search/replace project-wide     |
| `<leader>sw` | Spectre: replace word under cursor       |

## Motion & Jumping

| Key                | Action                                                |
| ------------------ | ----------------------------------------------------- |
| `s`                | **Flash jump** — 2-char label jump anywhere on screen |
| `S`                | Flash treesitter node jump                            |
| `<C-d>` / `<C-u>`  | **Smooth half-page scroll** (neoscroll)               |
| `<C-f>` / `<C-b>`  | Smooth full-page scroll                               |
| `zz` / `zt` / `zb` | Smooth center / top / bottom recenter                 |
| `j` / `k`          | Down/up by visual line (wrapping-safe)                |
| `n` / `N`          | Next/prev search result, centered                     |
| `[d` / `]d`        | Prev/next diagnostic                                  |
| `[h` / `]h`        | Prev/next git hunk                                    |
| `[t` / `]t`        | Prev/next TODO comment                                |
| `[a` / `]a`        | Prev/next symbol (aerial)                             |
| `[f` / `]f`        | Prev/next function (treesitter)                       |
| `[c` / `]c`        | Prev/next class (treesitter)                          |

## Windows & Buffers

| Key                                     | Action                       |
| --------------------------------------- | ---------------------------- |
| `<C-h/j/k/l>`                           | Move between splits          |
| `<C-Up/Down/Left/Right>`                | Resize split                 |
| `<leader>sv` / `<leader>sh`             | Vertical / horizontal split  |
| `<S-l>` / `<S-h>`                       | Next / prev buffer           |
| `<leader>bd`                            | Close buffer                 |
| `<leader>bo`                            | Close all other buffers      |
| `<leader>w` / `<leader>q` / `<leader>Q` | Save / quit / force quit all |

## File Explorer (neo-tree)

| Key                                   | Action                           |
| ------------------------------------- | -------------------------------- |
| `<leader>e`                           | Toggle explorer                  |
| `<leader>o`                           | Focus explorer                   |
| Inside tree: `l` / `h` / `<CR>` / `/` | Open / close / open / fuzzy find |

## LSP (active when a language server attaches)

| Key                         | Action                               |
| --------------------------- | ------------------------------------ |
| `gd`                        | Go to definition                     |
| `gD`                        | Go to declaration                    |
| `gr`                        | Find references                      |
| `gI`                        | Go to implementation                 |
| `gy`                        | Go to type definition                |
| `K`                         | Hover docs                           |
| `gK`                        | Signature help                       |
| `<leader>rn`                | Rename symbol                        |
| `<leader>ca`                | Code action (quick fixes, refactors) |
| `<leader>ih`                | Toggle inlay hints                   |
| `<leader>ss` / `<leader>sS` | Doc / workspace symbols              |

## TypeScript (when editing .ts/.tsx)

| Key           | Action                  |
| ------------- | ----------------------- |
| `<leader>tsi` | Add missing imports     |
| `<leader>tso` | Organize imports        |
| `<leader>tsu` | Remove unused imports   |
| `<leader>tsf` | Fix all auto-fixes      |
| `<leader>tsd` | Go to source definition |

## Diagnostics & Outline

| Key          | Action                                         |
| ------------ | ---------------------------------------------- |
| `<leader>xd` | Line diagnostics (float)                       |
| `<leader>xx` | Toggle Trouble panel (all diagnostics)         |
| `<leader>xX` | Buffer diagnostics                             |
| `<leader>xs` | Trouble symbols                                |
| `<leader>xl` | Trouble LSP                                    |
| `<leader>xq` | Trouble quickfix                               |
| `<leader>xi` | **Project health dashboard** (full repo audit) |
| `<leader>a`  | Toggle code outline (aerial)                   |

## Format & Code

| Key                         | Action                             |
| --------------------------- | ---------------------------------- |
| `<leader>cf`                | Format buffer (conform)            |
| `<leader>cF`                | Force format with LSP fallback     |
| `<leader>ct`                | Scan ghost twins (clone detection) |
| `<leader>cT`                | Clear ghost twins                  |
| `<leader>cn` / `<leader>cp` | Next / prev ghost twin             |

## Git

| Key                         | Action                      |
| --------------------------- | --------------------------- |
| `<leader>gg`                | **LazyGit** (full TUI)      |
| `<leader>gp`                | Preview hunk                |
| `<leader>gb` / `<leader>gB` | Blame line / toggle blame   |
| `<leader>gs` (visual)       | Stage hunk                  |
| `<leader>gr` (visual)       | Reset hunk                  |
| `<leader>gS` / `<leader>gR` | Stage / reset buffer        |
| `<leader>gu`                | Undo stage hunk             |
| `<leader>gd`                | Diffview (side-by-side)     |
| `<leader>gh` / `<leader>gH` | File history / repo history |
| `<leader>gc`                | Close diffview              |
| `<leader>gD`                | Diff this file              |

## Terminal & Tasks

| Key                                                       | Action                                                                        |
| --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `<leader>tt` / `<leader>tv` / `<leader>tf`                | Terminal horizontal / vertical / float                                        |
| `<leader>tp`                                              | IPython REPL                                                                  |
| `<leader>tn`                                              | Node REPL                                                                     |
| `<leader>tr`                                              | **Pick project task** (stack-tasks — detects npm/pnpm/yarn/bun/poetry/docker) |
| `<leader>tl`                                              | Run last task                                                                 |
| `<leader>tD` / `<leader>tT` / `<leader>tB` / `<leader>tL` | Run dev / test / build / lint                                                 |
| `<Esc>` (inside terminal)                                 | Exit terminal mode                                                            |

## Harpoon (quick file switching)

| Key                         | Action                      |
| --------------------------- | --------------------------- |
| `<leader>ha`                | Add current file to harpoon |
| `<leader>hh`                | Open harpoon menu           |
| `<leader>1..4`              | Jump to harpoon slot 1–4    |
| `<leader>hp` / `<leader>hn` | Prev / next harpoon         |

## Routes, HTTP, Env

| Key                         | Action                                               |
| --------------------------- | ---------------------------------------------------- |
| `<leader>rl`                | **Route lens** — list all API routes in project      |
| `<leader>rq`                | Send routes to quickfix                              |
| `<leader>rr`                | Run `.http` request (kulala)                         |
| `<leader>ra`                | Run all HTTP requests in file                        |
| `<leader>rp` / `<leader>rn` | Prev / next HTTP request                             |
| `<leader>ee`                | **Env sentinel** — find missing / duplicate env keys |
| `<leader>ec`                | Clear env diagnostics                                |

## package.json (when editing it)

| Key                                        | Action                       |
| ------------------------------------------ | ---------------------------- |
| `<leader>ns` / `<leader>nh`                | Show / hide package versions |
| `<leader>nu` / `<leader>ni` / `<leader>nd` | Update / install / delete    |
| `<leader>nv`                               | Change package version       |

## Sessions, UI, Misc

| Key                  | Action                                    |
| -------------------- | ----------------------------------------- |
| `<leader>ps`         | Restore last session for cwd              |
| `<leader>pl`         | Restore last session (global)             |
| `<leader>pd`         | Stop session saving                       |
| `<leader>u`          | Undo tree                                 |
| `<leader>z`          | Zen mode (distraction-free)               |
| `<leader>mp`         | Markdown preview                          |
| `<Esc>`              | Clear search highlight                    |
| `<leader>p` (visual) | Paste without yanking replaced text       |
| `<A-j>` / `<A-k>`    | Move line down / up (works in visual too) |
| `<` / `>` (visual)   | Indent / outdent, stay in selection       |

## Text Objects (visual/operator, mini.ai + treesitter)

Type these after `d/c/y/v`:

| Object      | Meaning                        |
| ----------- | ------------------------------ |
| `af` / `if` | A function / inside function   |
| `ac` / `ic` | A class / inside class         |
| `aa` / `ia` | A parameter / inside parameter |
| `ao` / `io` | A block/cond/loop / inside     |
| `aq` / `iq` | Quote (any) / inside           |
| `ab` / `ib` | Bracket / inside               |

**Surround** (nvim-surround): `ys{motion}{char}` add, `ds{char}` delete, `cs{old}{new}` change. Example: `ysiw"` wrap word in quotes.

## Plugins / Health

| Key / Command    | Action                                         |
| ---------------- | ---------------------------------------------- |
| `:Lazy`          | Plugin manager                                 |
| `:Mason`         | Install LSPs/formatters                        |
| `:checkhealth`   | Full health report                             |
| `:ProjectHealth` | Your dashboard (lint+tsc+ruff+hadolint rollup) |
| `:ConformInfo`   | Formatter status for current buffer            |
| `:LspInfo`       | Attached LSP servers                           |

## Discovery — forget any key?

Just press `<Space>` and wait — **which-key** shows menu of all leader bindings. Or run `<leader>fk` for searchable keymap list.

---

## Top 10 to memorize

1. `<leader>ff` — find files
2. `<leader>fg` — grep project
3. `<leader>e` — explorer
4. `<leader>gg` — LazyGit
5. `<leader>cf` — format
6. `<leader>ca` — code action
7. `<leader>rn` — rename symbol
8. `gd` — go to definition
9. `K` — hover docs
10. `<leader>xi` — project health dashboard
