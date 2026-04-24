local au = vim.api.nvim_create_autocmd
local ag = vim.api.nvim_create_augroup
local uv = vim.uv or vim.loop

local function apply_diagnostic_highlights()
  local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })
  vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
    fg = comment_hl.fg,
    italic = true,
    strikethrough = false,
  })
  vim.api.nvim_set_hl(0, "LspInlayHint", {
    italic = true,
    strikethrough = false,
  })
end

au("ColorScheme", {
  group = ag("DiagnosticStyleFix", { clear = true }),
  callback = apply_diagnostic_highlights,
})
vim.schedule(apply_diagnostic_highlights)

au("TextYankPost", {
  group = ag("YankHighlight", { clear = true }),
  callback = function()
    local on_yank = (vim.hl and vim.hl.on_yank) or vim.highlight.on_yank
    on_yank({ higroup = "IncSearch", timeout = 180 })
  end,
})

local trim_max_size = 512 * 1024
local trim_max_lines = 10000

local function should_trim_whitespace(bufnr)
  if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or name:match("/node_modules/") or name:match("/%.git/") then
    return false
  end

  local ok, stat = pcall(uv.fs_stat, name)
  if ok and stat and stat.size and stat.size > trim_max_size then
    return false
  end

  return vim.api.nvim_buf_line_count(bufnr) <= trim_max_lines
end

au("BufWritePre", {
  group = ag("TrimWhitespace", { clear = true }),
  callback = function(args)
    if not should_trim_whitespace(args.buf) then
      return
    end

    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

au("BufReadPost", {
  group = ag("RestoreCursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)

    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

au("FocusGained", {
  group = ag("CheckExternalChanges", { clear = true }),
  command = "checktime",
})

au("VimResized", {
  group = ag("ResizeSplits", { clear = true }),
  command = "tabdo wincmd =",
})

local function is_directory(path)
  local ok, stat = pcall(uv.fs_stat, path)
  return ok and stat and stat.type == "directory"
end

local function open_neotree(dir)
  local escaped = vim.fn.fnameescape(dir)
  vim.cmd("cd " .. escaped)

  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then
    pcall(lazy.load, { plugins = { "neo-tree.nvim" } })
  end

  return pcall(vim.cmd, "Neotree current dir=" .. escaped)
end

au("VimEnter", {
  group = ag("StartupLayout", { clear = true }),
  nested = true,
  callback = function()
    local argc = vim.fn.argc(-1)

    if argc == 1 then
      local arg0 = vim.fn.fnamemodify(vim.fn.argv(0), ":p")
      if is_directory(arg0) then
        open_neotree(arg0)
      end
    end
    -- Blank-buffer handling owned by alpha-nvim dashboard.
    -- Session restore is on-demand via <leader>ps / <leader>pl.
  end,
})

au("FileType", {
  group = ag("QuickClose", { clear = true }),
  pattern = { "help", "qf", "lspinfo", "man", "notify", "spectre_panel", "checkhealth", "startuptime" },
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = event.buf, silent = true })
  end,
})

au({ "BufRead", "BufNewFile" }, {
  group = ag("StackFiletypes", { clear = true }),
  pattern = {
    "*.env",
    ".env.*",
    "Dockerfile.*",
    "*.Dockerfile",
    "*.http",
    "*.rest",
  },
  callback = function(args)
    local name = vim.fn.fnamemodify(args.file, ":t")

    if name:match("^%.env") then
      vim.bo[args.buf].filetype = "dotenv"
    elseif name:match("Dockerfile") then
      vim.bo[args.buf].filetype = "dockerfile"
    elseif name:match("%.http$") or name:match("%.rest$") then
      vim.bo[args.buf].filetype = "http"
    end
  end,
})

au("FileType", {
  group = ag("PythonSettings", { clear = true }),
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.colorcolumn = "88"
  end,
})

au("FileType", {
  group = ag("MarkdownSettings", { clear = true }),
  pattern = { "markdown", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 100
  end,
})
