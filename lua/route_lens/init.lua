local M = {}

local defaults = {
  root_markers = { "package.json", "pyproject.toml", "requirements.txt", ".git" },
  globs = {
    "*.ts",
    "*.tsx",
    "*.js",
    "*.jsx",
    "*.mjs",
    "*.cjs",
    "*.py",
  },
  ignore = {
    "!.git",
    "!node_modules",
    "!dist",
    "!build",
    "!.next",
    "!coverage",
    "!venv",
    "!.venv",
  },
}

local config = vim.deepcopy(defaults)
local last_routes = {}

local rg_patterns = {
  [[\b(app|router|server)\.(get|post|put|patch|delete|options|head|all)\s*\(\s*['"`][^'"`]+]],
  [[\bfastify\.(get|post|put|patch|delete|options|head|all)\s*\(\s*['"`][^'"`]+]],
  [[@\w+\.(get|post|put|patch|delete|options|head)\s*\(\s*['"][^'"]+]],
  [[@(Get|Post|Put|Patch|Delete|Options|Head)\s*\(\s*['"][^'"]+]],
  [[export\s+(async\s+)?function\s+(GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD)\b]],
}

local function notify(message, level)
  vim.notify("route-lens.nvim: " .. message, level or vim.log.levels.INFO)
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

local function relpath(root, path)
  return vim.fs.relpath(root, path) or path
end

local function parse_line(line)
  local file, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")

  if not file then
    return nil
  end

  return file, tonumber(lnum) or 1, tonumber(col) or 1, text
end

local function extract_route(text)
  local method, path = text:match("[%.@]([%a_]+)%s*%(%s*['\"`]([^'\"`]+)")

  if method and path then
    return method:upper(), path
  end

  method, path = text:match("@([%u][%a]*)%s*%(%s*['\"]([^'\"]+)")
  if method and path then
    return method:upper(), path
  end

  method = text:match("export%s+async%s+function%s+([A-Z]+)%f[%W]")
    or text:match("export%s+function%s+([A-Z]+)%f[%W]")

  if method then
    return method:upper(), nil
  end

  return nil
end

local function route_from_next_file(file)
  local normalized = file:gsub("\\", "/")
  local path = normalized:match("app/(.*)/route%.[tj]sx?$")

  if path then
    return "/" .. path
  end

  path = normalized:match("pages/api/(.*)%.[tj]sx?$")
  if path then
    return "/api/" .. path
  end

  return nil
end

local function normalize_route(path)
  if not path or path == "" then
    return "(unknown)"
  end

  path = path:gsub("%[%.%.%.([^%]]+)%]", ":%1*")
  path = path:gsub("%[([^%]]+)%]", ":%1")
  path = path:gsub("/route$", "")
  path = path:gsub("/index$", "")

  if path == "" then
    return "/"
  end

  if path:sub(1, 1) ~= "/" then
    path = "/" .. path
  end

  return path
end

local function build_rg_command()
  local cmd = {
    "rg",
    "--line-number",
    "--column",
    "--no-heading",
    "--hidden",
    "--smart-case",
  }

  for _, glob in ipairs(config.globs) do
    vim.list_extend(cmd, { "-g", glob })
  end

  for _, glob in ipairs(config.ignore) do
    vim.list_extend(cmd, { "-g", glob })
  end

  for _, pattern in ipairs(rg_patterns) do
    vim.list_extend(cmd, { "-e", pattern })
  end

  return cmd
end

local function route_key(route)
  return table.concat({ route.file, route.lnum, route.col, route.method, route.path }, ":")
end

local function scan_with_rg(root)
  if vim.fn.executable("rg") ~= 1 then
    notify("ripgrep is required", vim.log.levels.WARN)
    return {}
  end

  local result = vim.system(build_rg_command(), { cwd = root, text = true }):wait()
  local routes = {}
  local seen = {}

  if result.code ~= 0 and (result.stdout or "") == "" then
    return routes
  end

  for line in (result.stdout or ""):gmatch("[^\r\n]+") do
    local file, lnum, col, text = parse_line(line)
    local method, path = extract_route(text or "")

    if file and method then
      path = path or route_from_next_file(file)
      local route = {
        file = file,
        lnum = lnum,
        col = col,
        method = method,
        path = normalize_route(path),
        text = vim.trim(text or ""),
      }
      local key = route_key(route)

      if not seen[key] then
        seen[key] = true
        routes[#routes + 1] = route
      end
    end
  end

  table.sort(routes, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end

    return a.lnum < b.lnum
  end)

  return routes
end

local function to_label(route)
  return string.format("%-7s %-35s %s:%d", route.method, route.path, route.file, route.lnum)
end

local function jump(root, route)
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. route.file))
  vim.api.nvim_win_set_cursor(0, { route.lnum, math.max(route.col - 1, 0) })
  vim.cmd("normal! zv")
end

function M.scan()
  local root = project_root()
  last_routes = scan_with_rg(root)
  return last_routes, root
end

function M.quickfix()
  local routes, root = M.scan()
  local items = {}

  for _, route in ipairs(routes) do
    items[#items + 1] = {
      filename = root .. "/" .. route.file,
      lnum = route.lnum,
      col = route.col,
      text = string.format("[%s] %s  %s", route.method, route.path, route.text),
    }
  end

  vim.fn.setqflist({}, "r", {
    title = "Route Lens",
    items = items,
  })

  if #items > 0 then
    vim.cmd("copen")
  end

  notify(string.format("found %d routes", #items))
end

function M.pick()
  local routes, root = M.scan()

  if #routes == 0 then
    notify("no routes found", vim.log.levels.WARN)
    return
  end

  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    local labels = {}
    local by_label = {}

    for _, route in ipairs(routes) do
      local label = to_label(route)
      labels[#labels + 1] = label
      by_label[label] = route
    end

    fzf.fzf_exec(labels, {
      prompt = "Routes> ",
      actions = {
        ["default"] = function(selected)
          local route = by_label[selected[1]]
          if route then
            jump(root, route)
          end
        end,
      },
    })
    return
  end

  vim.ui.select(routes, {
    prompt = "Route",
    format_item = to_label,
  }, function(route)
    if route then
      jump(root, route)
    end
  end)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  vim.api.nvim_create_user_command("RouteLens", M.pick, {
    desc = "Find API routes in the current project",
  })

  vim.api.nvim_create_user_command("RouteLensQuickfix", M.quickfix, {
    desc = "Send API routes to quickfix",
  })
end

return M
