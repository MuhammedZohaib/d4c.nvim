local M = {}

local ns = vim.api.nvim_create_namespace("env_sentinel")

local defaults = {
  root_markers = { ".env.example", ".env", "package.json", "pyproject.toml", ".git" },
  env_files = {
    ".env",
    ".env.local",
    ".env.development",
    ".env.test",
  },
  example_files = {
    ".env.example",
    ".env.sample",
    ".env.template",
  },
}

local config = vim.deepcopy(defaults)

local function notify(message, level)
  vim.notify("env-sentinel.nvim: " .. message, level or vim.log.levels.INFO)
end

local function path_join(a, b)
  if a:sub(-1) == "/" then
    return a .. b
  end

  return a .. "/" .. b
end

local function exists(path)
  return path and (vim.uv or vim.loop).fs_stat(path) ~= nil
end

local function current_dir()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
end

local function project_root()
  local found = vim.fs.find(config.root_markers, {
    upward = true,
    path = current_dir(),
    stop = vim.env.HOME,
  })[1]

  if found then
    return vim.fs.dirname(found)
  end

  return vim.fn.getcwd()
end

local function parse_env_file(path)
  local parsed = {
    path = path,
    keys = {},
    duplicates = {},
  }

  if not exists(path) then
    return parsed
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return parsed
  end

  for index, line in ipairs(lines) do
    local key = line:match("^%s*export%s+([%w_.-]+)%s*=") or line:match("^%s*([%w_.-]+)%s*=")

    if key and key ~= "" then
      if parsed.keys[key] then
        parsed.duplicates[#parsed.duplicates + 1] = {
          key = key,
          first_line = parsed.keys[key],
          line = index,
        }
      else
        parsed.keys[key] = index
      end
    end
  end

  return parsed
end

local function first_existing(root, names)
  for _, name in ipairs(names) do
    local path = path_join(root, name)

    if exists(path) then
      return path
    end
  end

  return nil
end

local function rel(root, path)
  return vim.fs.relpath(root, path) or path
end

function M.scan()
  local root = project_root()
  local example_path = first_existing(root, config.example_files)
  local issues = {}

  if not example_path then
    return issues, root, "no env example file found"
  end

  local example = parse_env_file(example_path)
  local actual_keys = {}
  local parsed_actual = {}

  for _, name in ipairs(config.env_files) do
    local path = path_join(root, name)

    if exists(path) then
      local parsed = parse_env_file(path)
      parsed_actual[#parsed_actual + 1] = parsed

      for key in pairs(parsed.keys) do
        actual_keys[key] = true
      end
    end
  end

  for key, line in pairs(example.keys) do
    if not actual_keys[key] then
      issues[#issues + 1] = {
        severity = vim.diagnostic.severity.WARN,
        file = example.path,
        line = line,
        key = key,
        message = key .. " is documented but missing from local env files",
      }
    end
  end

  for _, duplicate in ipairs(example.duplicates) do
    issues[#issues + 1] = {
      severity = vim.diagnostic.severity.WARN,
      file = example.path,
      line = duplicate.line,
      key = duplicate.key,
      message = duplicate.key .. " is duplicated in " .. rel(root, example.path),
    }
  end

  for _, parsed in ipairs(parsed_actual) do
    for _, duplicate in ipairs(parsed.duplicates) do
      issues[#issues + 1] = {
        severity = vim.diagnostic.severity.WARN,
        file = parsed.path,
        line = duplicate.line,
        key = duplicate.key,
        message = duplicate.key .. " is duplicated in " .. rel(root, parsed.path),
      }
    end
  end

  table.sort(issues, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end

    return a.line < b.line
  end)

  return issues, root
end

local function set_buffer_diagnostics(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)

  if name == "" or not name:match("/%.env") then
    return
  end

  local issues = M.scan()
  local diagnostics = {}

  for _, issue in ipairs(issues) do
    if vim.fs.normalize(issue.file) == vim.fs.normalize(name) then
      diagnostics[#diagnostics + 1] = {
        lnum = math.max(issue.line - 1, 0),
        col = 0,
        severity = issue.severity,
        source = "env-sentinel",
        message = issue.message,
      }
    end
  end

  vim.diagnostic.set(ns, bufnr, diagnostics)
end

function M.quickfix()
  local issues, root, note = M.scan()

  if note then
    notify(note, vim.log.levels.WARN)
  end

  local items = {}
  for _, issue in ipairs(issues) do
    items[#items + 1] = {
      filename = issue.file,
      lnum = issue.line,
      col = 1,
      text = issue.message,
      type = issue.severity == vim.diagnostic.severity.ERROR and "E" or "W",
    }
  end

  vim.fn.setqflist({}, "r", {
    title = "Env Sentinel",
    items = items,
  })

  if #items > 0 then
    vim.cmd("copen")
  end

  notify(string.format("found %d env issues in %s", #items, root))
end

function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  vim.api.nvim_create_user_command("EnvSentinel", M.quickfix, {
    desc = "Check env examples against local env files",
  })

  vim.api.nvim_create_user_command("EnvSentinelClear", function()
    M.clear(0)
  end, {
    desc = "Clear Env Sentinel diagnostics",
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("EnvSentinel", { clear = true }),
    pattern = ".env*",
    callback = function(args)
      set_buffer_diagnostics(args.buf)
    end,
  })
end

return M
