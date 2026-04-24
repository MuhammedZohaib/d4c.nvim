local M = {}

local defaults = {
  terminal_direction = "horizontal",
  terminal_size = 18,
  root_markers = {
    "package.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "bun.lockb",
    "bun.lock",
    "pyproject.toml",
    "requirements.txt",
    "Dockerfile",
    "docker-compose.yml",
    "compose.yml",
    ".git",
  },
}

local config = vim.deepcopy(defaults)
local last_task = nil

local aliases = {
  dev = { "dev", "start", "serve" },
  build = { "build" },
  test = { "test", "test:unit", "vitest", "jest" },
  lint = { "lint" },
  typecheck = { "typecheck", "type-check", "check-types", "tsc" },
  format = { "format", "fmt" },
}

local function notify(message, level)
  vim.notify("stack-tasks.nvim: " .. message, level or vim.log.levels.INFO)
end

local function path_join(...)
  return table.concat(vim.tbl_filter(function(part)
    return part and part ~= ""
  end, { ... }), "/")
end

local function exists(path)
  return path and (vim.uv or vim.loop).fs_stat(path) ~= nil
end

local function current_dir()
  local name = vim.api.nvim_buf_get_name(0)

  if name ~= "" then
    return vim.fs.dirname(name)
  end

  return vim.fn.getcwd()
end

local function project_root()
  local found = vim.fs.find(config.root_markers, {
    upward = true,
    path = current_dir(),
    stop = vim.env.HOME,
  })[1]

  if found then
    if vim.fn.fnamemodify(found, ":t") == ".git" then
      return vim.fs.dirname(found)
    end

    return vim.fs.dirname(found)
  end

  return vim.fn.getcwd()
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)

  if not ok then
    return nil
  end

  local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if ok_decode and type(decoded) == "table" then
    return decoded
  end

  return nil
end

local function package_manager(root)
  if exists(path_join(root, "pnpm-lock.yaml")) then
    return "pnpm"
  end

  if exists(path_join(root, "yarn.lock")) then
    return "yarn"
  end

  if exists(path_join(root, "bun.lockb")) or exists(path_join(root, "bun.lock")) then
    return "bun"
  end

  return "npm"
end

local function package_script_command(pm, script)
  if pm == "npm" then
    return "npm run " .. script
  end

  if pm == "yarn" then
    return "yarn " .. script
  end

  if pm == "bun" then
    return "bun run " .. script
  end

  return pm .. " " .. script
end

local function package_scripts(root)
  local package_json = read_json(path_join(root, "package.json"))
  local scripts = package_json and package_json.scripts
  local tasks = {}

  if type(scripts) ~= "table" then
    return tasks
  end

  local pm = package_manager(root)
  for name, command in pairs(scripts) do
    tasks[#tasks + 1] = {
      label = string.format("npm:%s -> %s", name, command),
      name = name,
      command = package_script_command(pm, name),
      cwd = root,
      source = "package.json",
    }
  end

  table.sort(tasks, function(a, b)
    return a.name < b.name
  end)

  return tasks
end

local function python_tasks(root)
  local has_python = exists(path_join(root, "pyproject.toml"))
    or exists(path_join(root, "requirements.txt"))
    or exists(path_join(root, "setup.py"))

  if not has_python then
    return {}
  end

  local tasks = {}

  if vim.fn.executable("pytest") == 1 then
    tasks[#tasks + 1] = { label = "python:test -> pytest", name = "pytest", command = "pytest", cwd = root, source = "python" }
  else
    tasks[#tasks + 1] = {
      label = "python:test -> python -m pytest",
      name = "pytest",
      command = "python -m pytest",
      cwd = root,
      source = "python",
    }
  end

  if vim.fn.executable("ruff") == 1 then
    tasks[#tasks + 1] = { label = "python:lint -> ruff check .", name = "ruff", command = "ruff check .", cwd = root, source = "python" }
    tasks[#tasks + 1] = {
      label = "python:format -> ruff format .",
      name = "ruff-format",
      command = "ruff format .",
      cwd = root,
      source = "python",
    }
  end

  return tasks
end

local function docker_tasks(root)
  local compose_file = exists(path_join(root, "docker-compose.yml")) or exists(path_join(root, "compose.yml"))
  local dockerfile = exists(path_join(root, "Dockerfile"))
  local tasks = {}

  if compose_file then
    tasks[#tasks + 1] = { label = "docker:up -> docker compose up", name = "docker-up", command = "docker compose up", cwd = root, source = "docker" }
    tasks[#tasks + 1] = {
      label = "docker:down -> docker compose down",
      name = "docker-down",
      command = "docker compose down",
      cwd = root,
      source = "docker",
    }
    tasks[#tasks + 1] = {
      label = "docker:logs -> docker compose logs -f --tail=200",
      name = "docker-logs",
      command = "docker compose logs -f --tail=200",
      cwd = root,
      source = "docker",
    }
  end

  if dockerfile then
    local image = vim.fn.fnamemodify(root, ":t"):gsub("[^%w_.-]", "-"):lower()
    tasks[#tasks + 1] = {
      label = "docker:build -> docker build",
      name = "docker-build",
      command = "docker build -t " .. image .. " .",
      cwd = root,
      source = "docker",
    }
  end

  return tasks
end

local function collect_tasks(root)
  local tasks = package_scripts(root)
  vim.list_extend(tasks, python_tasks(root))
  vim.list_extend(tasks, docker_tasks(root))
  tasks[#tasks + 1] = { label = "shell -> " .. vim.o.shell, name = "shell", command = vim.o.shell, cwd = root, source = "shell" }

  if vim.fn.executable("node") == 1 then
    tasks[#tasks + 1] = { label = "node -> node REPL", name = "node", command = "node", cwd = root, source = "repl" }
  end

  if vim.fn.executable("python3") == 1 then
    tasks[#tasks + 1] = { label = "python -> python3 REPL", name = "python", command = "python3", cwd = root, source = "repl" }
  end

  return tasks
end

local function task_for_alias(tasks, name)
  for _, task in ipairs(tasks) do
    if task.name == name then
      return task
    end
  end

  for _, candidate in ipairs(aliases[name] or {}) do
    for _, task in ipairs(tasks) do
      if task.name == candidate then
        return task
      end
    end
  end

  return nil
end

local function open_terminal(task)
  last_task = task

  local ok_terminal, terminal = pcall(require, "toggleterm.terminal")
  if ok_terminal then
    terminal.Terminal:new({
      cmd = task.command,
      dir = task.cwd,
      direction = config.terminal_direction,
      size = config.terminal_size,
      close_on_exit = false,
      hidden = true,
    }):toggle()
    return
  end

  vim.cmd("botright split")
  vim.cmd("resize " .. tostring(config.terminal_size))
  vim.cmd("lcd " .. vim.fn.fnameescape(task.cwd))
  vim.fn.termopen(task.command)
  vim.cmd("startinsert")
end

local function pick_with_fzf(tasks)
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if not ok_fzf then
    return false
  end

  local by_label = {}
  local labels = {}

  for _, task in ipairs(tasks) do
    by_label[task.label] = task
    labels[#labels + 1] = task.label
  end

  fzf.fzf_exec(labels, {
    prompt = "Tasks> ",
    actions = {
      ["default"] = function(selected)
        local task = by_label[selected[1]]
        if task then
          open_terminal(task)
        end
      end,
    },
  })

  return true
end

function M.list()
  return collect_tasks(project_root())
end

function M.pick()
  local tasks = M.list()

  if #tasks == 0 then
    notify("no tasks found", vim.log.levels.WARN)
    return
  end

  if pick_with_fzf(tasks) then
    return
  end

  vim.ui.select(tasks, {
    prompt = "Stack task",
    format_item = function(item)
      return item.label
    end,
  }, function(task)
    if task then
      open_terminal(task)
    end
  end)
end

function M.run(name)
  name = name and vim.trim(name) or ""

  if name == "" then
    M.pick()
    return
  end

  local tasks = M.list()
  local task = task_for_alias(tasks, name)

  if not task then
    notify("unknown task '" .. name .. "'", vim.log.levels.WARN)
    return
  end

  open_terminal(task)
end

function M.last()
  if not last_task then
    notify("no previous task", vim.log.levels.WARN)
    return
  end

  open_terminal(last_task)
end

function M.complete()
  local names = vim.tbl_keys(aliases)

  for _, task in ipairs(M.list()) do
    names[#names + 1] = task.name
  end

  table.sort(names)
  return names
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  vim.api.nvim_create_user_command("StackTasks", M.pick, {
    desc = "Pick and run a project task",
  })

  vim.api.nvim_create_user_command("StackRun", function(args)
    M.run(args.args)
  end, {
    nargs = "?",
    complete = function()
      return M.complete()
    end,
    desc = "Run a named project task",
  })

  vim.api.nvim_create_user_command("StackLast", M.last, {
    desc = "Re-run the last project task",
  })

  vim.api.nvim_create_user_command("StackRoot", function()
    print(project_root())
  end, {
    desc = "Print detected project root",
  })
end

return M
