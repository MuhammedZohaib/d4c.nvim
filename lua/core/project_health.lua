local M = {}

local uv = vim.uv or vim.loop

local state = {
  popup = nil,
  bufnr = nil,
  request_id = 0,
  hl_ns = vim.api.nvim_create_namespace("project_health_dashboard"),
}

local IGNORE_GLOBS = {
  "!.git",
  "!node_modules",
  "!dist",
  "!build",
  "!coverage",
  "!.next",
  "!vendor",
  "!target",
  "!out",
  "!tmp",
}

local CODE_FILE_GLOB = "*.{ts,tsx,js,jsx,mjs,cjs,lua,py,sh,bash,zsh,css,scss,sass,json,yaml,yml,md,mdx,toml,Dockerfile,dockerfile}"
local ENDPOINT_FILE_GLOB = "*.{ts,tsx,js,jsx,mjs,cjs,py}"

local ESLINT_CONFIG_GLOBS = {
  "eslint.config.js",
  "eslint.config.cjs",
  "eslint.config.mjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.mjs",
  ".eslintrc.json",
  ".eslintrc.yaml",
  ".eslintrc.yml",
}

local RUFF_CONFIG_GLOBS = {
  "pyproject.toml",
  "ruff.toml",
  ".ruff.toml",
}

local DOCKERFILE_GLOBS = {
  "Dockerfile",
  "Dockerfile.*",
  "*.Dockerfile",
  "dockerfile",
  "dockerfile.*",
}

local MAX_DIAGNOSTIC_LINES = 40
local MAX_ESLINT_PROJECTS = 14
local MAX_TSC_PROJECTS = 18
local MAX_RUFF_PROJECTS = 10
local MAX_DOCKER_FILES = 80

local UNUSED_TS_CODES = {
  ["6133"] = true,
  ["6192"] = true,
  ["6196"] = true,
}

local SECTION_HEADERS = {
  Scope = true,
  ["Codebase Footprint"] = true,
  ["Diagnostics Snapshot"] = true,
  ["Monorepo Coverage"] = true,
  ["Tool Coverage"] = true,
  ["Runtime Errors"] = true,
  ["Top Diagnostic Lines"] = true,
}

local function buf_valid(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function win_valid(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function split_lines(text)
  local lines = {}
  if not text or text == "" then
    return lines
  end
  for line in text:gmatch("[^\r\n]+") do
    if line ~= "" then
      lines[#lines + 1] = line
    end
  end
  return lines
end

local function line_count(text)
  local count = 0
  for _ in (text or ""):gmatch("[^\r\n]+") do
    count = count + 1
  end
  return count
end

local function format_number(n)
  local s = tostring(n or 0)
  local left, num, right = s:match("^([^%d]*%d)(%d*)(.-)$")
  return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local function severity_rank(sev)
  if sev == "error" then
    return 1
  end
  if sev == "warn" then
    return 2
  end
  if sev == "info" then
    return 3
  end
  return 4
end

local function path_depth(path)
  local _, count = path:gsub("/", "")
  return count
end

local function is_abs_path(path)
  if not path or path == "" then
    return false
  end
  return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil
end

local function path_join(a, b)
  if a:sub(-1) == "/" then
    return a .. b
  end
  return a .. "/" .. b
end

local function to_abs_path(path, cwd)
  if not path or path == "" then
    return cwd
  end
  if is_abs_path(path) then
    return vim.fs.normalize(path)
  end
  return vim.fs.normalize(path_join(cwd, path))
end

local function to_rel_path(path, cwd)
  if not path or path == "" then
    return "(unknown)"
  end

  local abs = is_abs_path(path) and vim.fs.normalize(path) or to_abs_path(path, cwd)
  local rel = vim.fs.relpath(cwd, abs)
  return rel or abs
end

local function dedupe_list(values)
  local seen = {}
  local out = {}
  for _, value in ipairs(values or {}) do
    if value and value ~= "" and not seen[value] then
      seen[value] = true
      out[#out + 1] = value
    end
  end
  return out
end

local function sort_and_cap(paths, max_items)
  table.sort(paths, function(a, b)
    local da, db = path_depth(a), path_depth(b)
    if da ~= db then
      return da < db
    end
    return a < b
  end)

  local capped = {}
  for i = 1, math.min(#paths, max_items) do
    capped[#capped + 1] = paths[i]
  end
  return capped
end

local function is_vim_nil(value)
  return vim.NIL ~= nil and value == vim.NIL
end

local function as_string(value, default)
  if value == nil or is_vim_nil(value) then
    return default or ""
  end

  local t = type(value)
  if t == "string" then
    return value
  end
  if t == "number" or t == "boolean" then
    return tostring(value)
  end

  return default or ""
end

local function as_number(value, default)
  if value == nil or is_vim_nil(value) then
    return default or 0
  end
  return tonumber(value) or (default or 0)
end

local function decode_json_flexible(payload)
  if not payload or payload == "" then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, payload)
  if ok and type(decoded) == "table" then
    return decoded
  end

  local array_start = payload:find("%[")
  local array_end = payload:match(".*()%]")
  if array_start and array_end and array_end > array_start then
    local ok_arr, decoded_arr = pcall(vim.json.decode, payload:sub(array_start, array_end))
    if ok_arr and type(decoded_arr) == "table" then
      return decoded_arr
    end
  end

  local obj_start = payload:find("{")
  local obj_end = payload:match(".*()}")
  if obj_start and obj_end and obj_end > obj_start then
    local ok_obj, decoded_obj = pcall(vim.json.decode, payload:sub(obj_start, obj_end))
    if ok_obj and type(decoded_obj) == "table" then
      return decoded_obj
    end
  end

  return nil
end

local function first_non_empty_line(text)
  for _, line in ipairs(split_lines(text or "")) do
    if line and line ~= "" then
      return line
    end
  end
  return nil
end

local function make_rg_cmd(base)
  local cmd = { "rg" }
  for _, arg in ipairs(base) do
    cmd[#cmd + 1] = arg
  end
  cmd[#cmd + 1] = "--hidden"
  for _, glob in ipairs(IGNORE_GLOBS) do
    cmd[#cmd + 1] = "--glob"
    cmd[#cmd + 1] = glob
  end
  return cmd
end

local function run_command(cmd, cwd, cb)
  local done = false
  local function finish(res)
    if done then
      return
    end
    done = true
    vim.schedule(function()
      cb({
        code = res.code or 1,
        stdout = res.stdout or "",
        stderr = res.stderr or "",
      })
    end)
  end

  if vim.system then
    local ok, err = pcall(vim.system, cmd, {
      text = true,
      cwd = cwd,
      timeout = 120000,
    }, function(res)
      finish(res or {})
    end)

    if not ok then
      finish({
        code = 1,
        stderr = tostring(err),
      })
    end
    return
  end

  local stdout_lines = {}
  local stderr_lines = {}
  local timer = uv.new_timer()

  local function append_lines(dst, data)
    if type(data) ~= "table" then
      return
    end
    for _, line in ipairs(data) do
      if line and line ~= "" then
        dst[#dst + 1] = line
      end
    end
  end

  local job_id = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      append_lines(stdout_lines, data)
    end,
    on_stderr = function(_, data)
      append_lines(stderr_lines, data)
    end,
    on_exit = function(_, code)
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
      finish({
        code = code or 1,
        stdout = table.concat(stdout_lines, "\n"),
        stderr = table.concat(stderr_lines, "\n"),
      })
    end,
  })

  if job_id <= 0 then
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
    finish({
      code = 1,
      stderr = "failed to start command",
    })
    return
  end

  if timer then
    timer:start(120000, 0, function()
      vim.schedule(function()
        if timer then
          timer:stop()
          timer:close()
          timer = nil
        end
        pcall(vim.fn.jobstop, job_id)
        finish({
          code = 124,
          stdout = table.concat(stdout_lines, "\n"),
          stderr = table.concat(stderr_lines, "\n"),
        })
      end)
    end)
  end
end

local function run_many(items, worker, done)
  if #items == 0 then
    done()
    return
  end

  local pending = #items
  for _, item in ipairs(items) do
    worker(item, function()
      pending = pending - 1
      if pending == 0 then
        done()
      end
    end)
  end
end

local function discover_files(cwd, globs, cb)
  local cmd = make_rg_cmd({ "--files" })
  for _, glob in ipairs(globs) do
    cmd[#cmd + 1] = "-g"
    cmd[#cmd + 1] = glob
  end

  run_command(cmd, cwd, function(res)
    if res.code == 0 or res.code == 1 then
      cb(split_lines(res.stdout))
      return
    end
    cb({})
  end)
end

local function pick_node_tool(project_root, workspace_root, tool)
  local candidates = {
    path_join(project_root, "node_modules/.bin/" .. tool),
    path_join(workspace_root, "node_modules/.bin/" .. tool),
  }

  for _, candidate in ipairs(candidates) do
    if uv.fs_stat(candidate) then
      return { candidate }
    end
  end

  if vim.fn.executable(tool) == 1 then
    return { tool }
  end

  return nil
end

local function pick_ruff_tool(project_root, workspace_root)
  local candidates = {
    path_join(project_root, ".venv/bin/ruff"),
    path_join(workspace_root, ".venv/bin/ruff"),
  }

  for _, candidate in ipairs(candidates) do
    if uv.fs_stat(candidate) then
      return candidate
    end
  end

  if vim.fn.executable("ruff") == 1 then
    return "ruff"
  end

  return nil
end

local function add_diag(summary, diag)
  summary._seen = summary._seen or {}
  local key = table.concat({
    diag.tool or "tool",
    diag.severity or "info",
    diag.file or "",
    tostring(diag.line or 0),
    tostring(diag.col or 0),
    diag.message or "",
  }, "|")

  if summary._seen[key] then
    return
  end

  summary._seen[key] = true
  summary.diagnostics[#summary.diagnostics + 1] = diag
end

local function finalize_summary(summary)
  summary._seen = nil
  return summary
end

local function ensure_highlight_groups()
  vim.api.nvim_set_hl(0, "ProjectHealthTitle", { link = "Title", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthSection", { link = "Keyword", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthLabel", { link = "Identifier", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthNumber", { link = "Number", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthMuted", { link = "Comment", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthTool", { link = "Special", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthError", { link = "DiagnosticError", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthWarn", { link = "DiagnosticWarn", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthInfo", { link = "DiagnosticInfo", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthHint", { link = "DiagnosticHint", default = false })
  vim.api.nvim_set_hl(0, "ProjectHealthPath", { link = "Directory", default = false })
end

local function add_highlight(line_idx, start_col, end_col, group)
  if not buf_valid(state.bufnr) then
    return
  end
  local line_len = 0
  local ok_line, line_text = pcall(vim.api.nvim_buf_get_lines, state.bufnr, line_idx, line_idx + 1, false)
  if ok_line and line_text[1] then
    line_len = #line_text[1]
  end
  local resolved_end = end_col == -1 and line_len or end_col
  if resolved_end <= start_col then
    return
  end
  pcall(vim.api.nvim_buf_set_extmark, state.bufnr, state.hl_ns, line_idx, start_col, {
    end_col = resolved_end,
    hl_group = group,
    strict = false,
  })
end

local function highlight_token(line, line_idx, token, group)
  local from = 1
  while true do
    local s, e = line:find(token, from, true)
    if not s then
      break
    end
    add_highlight(line_idx, s - 1, e, group)
    from = e + 1
  end
end

local function highlight_numbers(line, line_idx)
  local from = 1
  while true do
    local s, e = line:find("%d[%d,]*", from)
    if not s then
      break
    end
    add_highlight(line_idx, s - 1, e, "ProjectHealthNumber")
    from = e + 1
  end
end

local function apply_dashboard_highlights(lines)
  if not buf_valid(state.bufnr) then
    return
  end

  ensure_highlight_groups()
  vim.api.nvim_buf_clear_namespace(state.bufnr, state.hl_ns, 0, -1)

  for idx, line in ipairs(lines) do
    local line_idx = idx - 1

    if line == "PROJECT HEALTH INSIGHTS (READ-ONLY)" then
      add_highlight(line_idx, 0, -1, "ProjectHealthTitle")
    elseif line:match("^=+$") then
      add_highlight(line_idx, 0, -1, "ProjectHealthMuted")
    elseif SECTION_HEADERS[line] then
      add_highlight(line_idx, 0, -1, "ProjectHealthSection")
    end

    local label_end = line:find(":", 1, true)
    if label_end and line:find("^  [^:]+:") then
      add_highlight(line_idx, 2, label_end - 1, "ProjectHealthLabel")
    end

    if line:find("%sRoot:%s") then
      local path_start = line:find("Root:", 1, true)
      if path_start then
        local colon = line:find(":", path_start, true)
        if colon then
          add_highlight(line_idx, colon + 1, -1, "ProjectHealthPath")
        end
      end
    end

    if line:find("^  %d+%. ") then
      local file_start, file_end = line:find("%s([^%s]+:%d+:%d+)%s")
      if file_start and file_end then
        add_highlight(line_idx, file_start, file_end - 1, "ProjectHealthPath")
      end
    end

    highlight_numbers(line, line_idx)

    highlight_token(line, line_idx, "[ERROR]", "ProjectHealthError")
    highlight_token(line, line_idx, "[WARN]", "ProjectHealthWarn")
    highlight_token(line, line_idx, "[INFO]", "ProjectHealthInfo")
    highlight_token(line, line_idx, "[HINT]", "ProjectHealthHint")

    highlight_token(line, line_idx, "[eslint]", "ProjectHealthTool")
    highlight_token(line, line_idx, "[tsc]", "ProjectHealthTool")
    highlight_token(line, line_idx, "[ruff]", "ProjectHealthTool")
    highlight_token(line, line_idx, "[hadolint]", "ProjectHealthTool")

    if line:find("Keys:", 1, true) then
      add_highlight(line_idx, 0, -1, "ProjectHealthMuted")
      highlight_token(line, line_idx, "[r]", "ProjectHealthInfo")
      highlight_token(line, line_idx, "[q]", "ProjectHealthWarn")
      highlight_token(line, line_idx, "[Esc]", "ProjectHealthWarn")
    end
  end
end

local function set_popup_lines(lines)
  if not buf_valid(state.bufnr) then
    return
  end

  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
  vim.bo[state.bufnr].readonly = true

  apply_dashboard_highlights(lines)
end

local function collect_footprint(cwd, done)
  local result = {
    total_files = 0,
    code_files = 0,
    loc = 0,
    endpoints = 0,
  }

  local pending = 4
  local function finish()
    pending = pending - 1
    if pending == 0 then
      done(result)
    end
  end

  run_command(make_rg_cmd({ "--files" }), cwd, function(res)
    if res.code == 0 then
      result.total_files = line_count(res.stdout)
    end
    finish()
  end)

  run_command(make_rg_cmd({ "--files", "-g", CODE_FILE_GLOB }), cwd, function(res)
    if res.code == 0 then
      result.code_files = line_count(res.stdout)
    end
    finish()
  end)

  run_command(make_rg_cmd({ "-c", "^", "-g", CODE_FILE_GLOB }), cwd, function(res)
    if res.code == 0 then
      for _, line in ipairs(split_lines(res.stdout)) do
        local n = tonumber(line:match(":(%d+)$"))
        if n then
          result.loc = result.loc + n
        end
      end
    end
    finish()
  end)

  run_command(make_rg_cmd({
    "-n",
    "-g",
    ENDPOINT_FILE_GLOB,
    "-e",
    [[\b(app|router)\.(get|post|put|patch|delete|options|head|all)\s*\(]],
    "-e",
    [[\bfastify\.(get|post|put|patch|delete|options|head|all)\s*\(]],
    "-e",
    [[\bkoa\.(use)\s*\(]],
    "-e",
    [[@(Get|Post|Put|Patch|Delete|Options|Head)\s*\(]],
    "-e",
    [[Route\(("|')]],
    "-e",
    [[export\s+async\s+function\s+(GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD)\b]],
  }), cwd, function(res)
    if res.code == 0 then
      result.endpoints = line_count(res.stdout)
    end
    finish()
  end)
end

local function collect_eslint(cwd, done)
  local summary = {
    available = false,
    ran = false,
    ok = false,
    errors = 0,
    warnings = 0,
    unused_imports = 0,
    diagnostics = {},
    projects = 0,
    discovered = 0,
    failures = 0,
    note = "eslint not found",
  }

  discover_files(cwd, ESLINT_CONFIG_GLOBS, function(config_files)
    local roots = {}
    for _, file in ipairs(config_files) do
      roots[#roots + 1] = vim.fs.dirname(file)
    end

    if #roots == 0 then
      roots = { "." }
    end

    roots = dedupe_list(roots)
    summary.discovered = #roots
    roots = sort_and_cap(roots, MAX_ESLINT_PROJECTS)
    summary.projects = #roots

    run_many(roots, function(root_rel, next_root)
      local root_abs = to_abs_path(root_rel, cwd)
      local runner = pick_node_tool(root_abs, cwd, "eslint")
      if not runner then
        summary.failures = summary.failures + 1
        next_root()
        return
      end

      summary.available = true
      summary.ran = true

      local cmd = vim.list_extend(vim.deepcopy(runner), {
        ".",
        "--ext",
        ".js,.jsx,.ts,.tsx,.mjs,.cjs",
        "--format",
        "json",
        "--no-error-on-unmatched-pattern",
      })

      run_command(cmd, root_abs, function(res)
        local decoded = decode_json_flexible(res.stdout)
        if type(decoded) ~= "table" then
          summary.failures = summary.failures + 1
          next_root()
          return
        end

        for _, file_report in ipairs(decoded) do
          local file_path = as_string(file_report.filePath)
          local rel_file = to_rel_path(file_path, cwd)
          for _, msg in ipairs(file_report.messages or {}) do
            local sev = (msg.severity == 2) and "error" or "warn"
            if sev == "error" then
              summary.errors = summary.errors + 1
            else
              summary.warnings = summary.warnings + 1
            end

            local message = as_string(msg.message)
            local rule = as_string(msg.ruleId)
            local lowered = message:lower()
            local is_unused = lowered:find("unused", 1, true) ~= nil
              and (lowered:find("import", 1, true) ~= nil or rule:find("unused", 1, true) ~= nil)

            if is_unused then
              summary.unused_imports = summary.unused_imports + 1
            end

            if #summary.diagnostics < 220 then
              add_diag(summary, {
                tool = "eslint",
                severity = sev,
                file = rel_file,
                line = as_number(msg.line),
                col = as_number(msg.column),
                message = message,
              })
            end
          end
        end

        next_root()
      end)
    end, function()
      if not summary.available then
        summary.note = "eslint binary not found in workspace"
        done(finalize_summary(summary))
        return
      end

      local capped = summary.discovered > summary.projects
      local core = string.format(
        "ok (%d roots, %d issues, %d failed)",
        summary.projects,
        summary.errors + summary.warnings,
        summary.failures
      )

      if capped then
        core = core .. string.format(" [capped %d/%d]", summary.projects, summary.discovered)
      end

      summary.ok = summary.failures < summary.projects
      summary.note = core
      done(finalize_summary(summary))
    end)
  end)
end

local function parse_tsc_line(line)
  local file, lnum, col, code, msg = line:match("^(.+)%((%d+),(%d+)%)%: error TS(%d+):%s*(.+)$")
  if file then
    return file, tonumber(lnum) or 0, tonumber(col) or 0, code, msg
  end

  file, lnum, col, code, msg = line:match("^(.+):(%d+):(%d+) %- error TS(%d+):%s*(.+)$")
  if file then
    return file, tonumber(lnum) or 0, tonumber(col) or 0, code, msg
  end

  local code_only, msg_only = line:match("^error TS(%d+):%s*(.+)$")
  if code_only then
    return nil, 0, 0, code_only, msg_only
  end

  return nil
end

local function collect_tsc(cwd, done)
  local summary = {
    available = false,
    ran = false,
    ok = false,
    errors = 0,
    unused_imports = 0,
    diagnostics = {},
    projects = 0,
    discovered = 0,
    failures = 0,
    note = "tsc not found",
  }

  discover_files(cwd, { "tsconfig*.json" }, function(tsconfigs)
    tsconfigs = dedupe_list(tsconfigs)
    summary.discovered = #tsconfigs

    if #tsconfigs == 0 then
      summary.available = true
      summary.note = "tsconfig not found"
      done(finalize_summary(summary))
      return
    end

    tsconfigs = sort_and_cap(tsconfigs, MAX_TSC_PROJECTS)
    summary.projects = #tsconfigs

    run_many(tsconfigs, function(tsconfig_rel, next_project)
      local tsconfig_abs = to_abs_path(tsconfig_rel, cwd)
      local project_root = vim.fs.dirname(tsconfig_abs)
      local runner = pick_node_tool(project_root, cwd, "tsc")

      if not runner then
        summary.failures = summary.failures + 1
        next_project()
        return
      end

      summary.available = true
      summary.ran = true

      local cmd = vim.list_extend(vim.deepcopy(runner), {
        "-p",
        tsconfig_abs,
        "--noEmit",
        "--pretty",
        "false",
      })

      run_command(cmd, project_root, function(res)
        local output = (res.stdout or "") .. "\n" .. (res.stderr or "")
        local local_error_count = 0

        for _, line in ipairs(split_lines(output)) do
          if line:find("error TS%d+:") then
            local file, line_num, col, code, msg = parse_tsc_line(line)
            local_error_count = local_error_count + 1
            summary.errors = summary.errors + 1

            if UNUSED_TS_CODES[tostring(code)] then
              summary.unused_imports = summary.unused_imports + 1
            else
              local lowered = (msg or line):lower()
              if lowered:find("unused", 1, true) and lowered:find("import", 1, true) then
                summary.unused_imports = summary.unused_imports + 1
              end
            end

            if #summary.diagnostics < 240 then
              local rel_file = tsconfig_rel
              if file and file ~= "" then
                rel_file = to_rel_path(file, project_root)
                if rel_file:find("^%.%./") then
                  rel_file = to_rel_path(to_abs_path(file, project_root), cwd)
                end
              end

              add_diag(summary, {
                tool = "tsc",
                severity = "error",
                file = rel_file,
                line = line_num or 0,
                col = col or 0,
                message = (code and ("TS" .. code .. " " .. (msg or ""))) or (msg or line),
              })
            end
          end
        end

        if res.code ~= 0 and local_error_count == 0 then
          summary.failures = summary.failures + 1
        end

        next_project()
      end)
    end, function()
      if not summary.available then
        summary.note = "tsc binary not found in workspace"
        done(finalize_summary(summary))
        return
      end

      local capped = summary.discovered > summary.projects
      local core = string.format(
        "ok (%d projects, %d errors, %d failed)",
        summary.projects,
        summary.errors,
        summary.failures
      )

      if capped then
        core = core .. string.format(" [capped %d/%d]", summary.projects, summary.discovered)
      end

      summary.ok = summary.failures < summary.projects
      summary.note = core
      done(finalize_summary(summary))
    end)
  end)
end

local function collect_ruff(cwd, done)
  local summary = {
    available = false,
    ran = false,
    ok = false,
    warnings = 0,
    unused_imports = 0,
    diagnostics = {},
    projects = 0,
    discovered = 0,
    failures = 0,
    note = "ruff not found",
  }

  discover_files(cwd, RUFF_CONFIG_GLOBS, function(config_files)
    local roots = {}
    for _, file in ipairs(config_files) do
      roots[#roots + 1] = vim.fs.dirname(file)
    end

    if #roots == 0 then
      roots = { "." }
    end

    roots = dedupe_list(roots)
    summary.discovered = #roots
    roots = sort_and_cap(roots, MAX_RUFF_PROJECTS)
    summary.projects = #roots

    run_many(roots, function(root_rel, next_root)
      local root_abs = to_abs_path(root_rel, cwd)
      local ruff_bin = pick_ruff_tool(root_abs, cwd)
      if not ruff_bin then
        summary.failures = summary.failures + 1
        next_root()
        return
      end

      summary.available = true
      summary.ran = true

      run_command({ ruff_bin, "check", ".", "--output-format", "json" }, root_abs, function(res)
        local decoded = decode_json_flexible(res.stdout)
        if type(decoded) ~= "table" then
          local stderr_line = first_non_empty_line(res.stderr)
          if stderr_line and not stderr_line:find("No Python files found", 1, true) then
            summary.failures = summary.failures + 1
          end
          next_root()
          return
        end

        for _, item in ipairs(decoded) do
          summary.warnings = summary.warnings + 1

          local message = as_string(item.message)
          local code = as_string(item.code)
          local loc = item.location or {}

          if code == "F401" or (message:lower():find("unused", 1, true) and message:lower():find("import", 1, true)) then
            summary.unused_imports = summary.unused_imports + 1
          end

          if #summary.diagnostics < 180 then
            local raw_file = as_string(item.filename, root_rel)
            local rel_file = to_rel_path(raw_file, root_abs)
            if rel_file:find("^%.%./") then
              rel_file = to_rel_path(to_abs_path(raw_file, root_abs), cwd)
            end

            add_diag(summary, {
              tool = "ruff",
              severity = "warn",
              file = rel_file,
              line = as_number(loc.row),
              col = as_number(loc.column),
              message = (code ~= "" and (code .. " " .. message)) or message,
            })
          end
        end

        next_root()
      end)
    end, function()
      if not summary.available then
        summary.note = "ruff binary not found"
        done(finalize_summary(summary))
        return
      end

      local capped = summary.discovered > summary.projects
      local core = string.format(
        "ok (%d roots, %d findings, %d failed)",
        summary.projects,
        summary.warnings,
        summary.failures
      )

      if capped then
        core = core .. string.format(" [capped %d/%d]", summary.projects, summary.discovered)
      end

      summary.ok = summary.failures < summary.projects
      summary.note = core
      done(finalize_summary(summary))
    end)
  end)
end

local function collect_hadolint(cwd, done)
  local summary = {
    available = false,
    ran = false,
    ok = false,
    errors = 0,
    warnings = 0,
    diagnostics = {},
    files = 0,
    discovered = 0,
    failures = 0,
    note = "hadolint not found",
  }

  if vim.fn.executable("hadolint") ~= 1 then
    done(finalize_summary(summary))
    return
  end

  summary.available = true

  discover_files(cwd, DOCKERFILE_GLOBS, function(files)
    files = dedupe_list(files)
    summary.discovered = #files

    if #files == 0 then
      summary.ok = true
      summary.note = "ok (no dockerfiles found)"
      done(finalize_summary(summary))
      return
    end

    files = sort_and_cap(files, MAX_DOCKER_FILES)
    summary.files = #files
    summary.ran = true

    run_many(files, function(file_rel, next_file)
      local file_abs = to_abs_path(file_rel, cwd)
      run_command({ "hadolint", "-f", "json", file_abs }, cwd, function(res)
        local decoded = decode_json_flexible(res.stdout)
        if type(decoded) ~= "table" then
          summary.failures = summary.failures + 1
          next_file()
          return
        end

        for _, finding in ipairs(decoded) do
          local level = as_string(finding.level, "warning"):lower()
          local sev = (level == "error") and "error" or "warn"

          if sev == "error" then
            summary.errors = summary.errors + 1
          else
            summary.warnings = summary.warnings + 1
          end

          if #summary.diagnostics < 160 then
            add_diag(summary, {
              tool = "hadolint",
              severity = sev,
              file = to_rel_path(as_string(finding.file, file_abs), cwd),
              line = as_number(finding.line),
              col = as_number(finding.column),
              message = string.format("%s %s", as_string(finding.code, "DL"), as_string(finding.message)),
            })
          end
        end

        next_file()
      end)
    end, function()
      local capped = summary.discovered > summary.files
      local core = string.format(
        "ok (%d dockerfiles, %d findings, %d failed)",
        summary.files,
        summary.errors + summary.warnings,
        summary.failures
      )

      if capped then
        core = core .. string.format(" [capped %d/%d]", summary.files, summary.discovered)
      end

      summary.ok = summary.failures < summary.files
      summary.note = core
      done(finalize_summary(summary))
    end)
  end)
end

local function build_dashboard(data)
  local diagnostics = {}

  for _, item in ipairs(data.eslint.diagnostics or {}) do
    diagnostics[#diagnostics + 1] = item
  end
  for _, item in ipairs(data.tsc.diagnostics or {}) do
    diagnostics[#diagnostics + 1] = item
  end
  for _, item in ipairs(data.ruff.diagnostics or {}) do
    diagnostics[#diagnostics + 1] = item
  end
  for _, item in ipairs(data.hadolint.diagnostics or {}) do
    diagnostics[#diagnostics + 1] = item
  end

  table.sort(diagnostics, function(a, b)
    local ra = severity_rank(a.severity)
    local rb = severity_rank(b.severity)
    if ra ~= rb then
      return ra < rb
    end

    local fa = a.file or ""
    local fb = b.file or ""
    if fa ~= fb then
      return fa < fb
    end

    if (a.line or 0) ~= (b.line or 0) then
      return (a.line or 0) < (b.line or 0)
    end

    return (a.col or 0) < (b.col or 0)
  end)

  local errors = (data.eslint.errors or 0) + (data.tsc.errors or 0) + (data.hadolint.errors or 0)
  local warnings = (data.eslint.warnings or 0) + (data.ruff.warnings or 0) + (data.hadolint.warnings or 0)
  local unused = (data.eslint.unused_imports or 0) + (data.tsc.unused_imports or 0) + (data.ruff.unused_imports or 0)
  local lint_findings = (data.eslint.errors or 0)
    + (data.eslint.warnings or 0)
    + (data.ruff.warnings or 0)
    + (data.hadolint.errors or 0)
    + (data.hadolint.warnings or 0)
  local total_issues = errors + warnings

  local lines = {
    "PROJECT HEALTH INSIGHTS (READ-ONLY)",
    string.rep("=", 78),
    "",
    "Scope",
    "  Root: " .. (data.cwd or ""),
    "  Generated: " .. os.date("%Y-%m-%d %H:%M:%S"),
    "  Refresh time: " .. tostring(data.elapsed_ms or 0) .. " ms",
    "",
    "Codebase Footprint",
    "  Total files scanned: " .. format_number(data.footprint.total_files or 0),
    "  Code files: " .. format_number(data.footprint.code_files or 0),
    "  Lines of code (estimated): " .. format_number(data.footprint.loc or 0),
    "  Backend endpoint candidates: " .. format_number(data.footprint.endpoints or 0),
    "",
    "Diagnostics Snapshot",
    "  Total issues: " .. format_number(total_issues),
    "  Errors: " .. format_number(errors),
    "  Warnings: " .. format_number(warnings),
    "  Lint findings (ESLint + Ruff + Hadolint): " .. format_number(lint_findings),
    "  TypeScript errors: " .. format_number(data.tsc.errors or 0),
    "  Unused imports: " .. format_number(unused),
    "",
    "Monorepo Coverage",
    string.format("  ESLint roots analyzed: %d (discovered %d)", data.eslint.projects or 0, data.eslint.discovered or 0),
    string.format("  TypeScript projects analyzed: %d (discovered %d)", data.tsc.projects or 0, data.tsc.discovered or 0),
    string.format("  Ruff roots analyzed: %d (discovered %d)", data.ruff.projects or 0, data.ruff.discovered or 0),
    string.format("  Dockerfiles analyzed: %d (discovered %d)", data.hadolint.files or 0, data.hadolint.discovered or 0),
    "",
    "Tool Coverage",
    string.format("  ESLint: %s", data.eslint.note or "n/a"),
    string.format("  TypeScript (tsc): %s", data.tsc.note or "n/a"),
    string.format("  Ruff: %s", data.ruff.note or "n/a"),
    string.format("  Hadolint: %s", data.hadolint.note or "n/a"),
    "",
  }

  if data.runtime_errors and #data.runtime_errors > 0 then
    lines[#lines + 1] = "Runtime Errors"
    for i, err in ipairs(data.runtime_errors) do
      lines[#lines + 1] = string.format("  %02d. %s", i, err)
    end
    lines[#lines + 1] = ""
  end

  lines[#lines + 1] = "Top Diagnostic Lines"

  if #diagnostics == 0 then
    lines[#lines + 1] = "  No diagnostics captured by configured analyzers."
  else
    for i = 1, math.min(#diagnostics, MAX_DIAGNOSTIC_LINES) do
      local d = diagnostics[i]
      local sev = (d.severity or "info"):upper()
      local file = d.file or "(unknown)"
      local lnum = d.line or 0
      local col = d.col or 0
      local msg = (d.message or ""):gsub("%s+", " ")
      lines[#lines + 1] = string.format("  %02d. [%s][%s] %s:%d:%d  %s", i, sev, d.tool or "tool", file, lnum, col, msg)
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Keys: [r] refresh   [q]/[Esc] close"

  return lines
end

local function close_popup()
  if state.popup then
    pcall(state.popup.unmount, state.popup)
  end
  state.popup = nil
  state.bufnr = nil
end

function M.refresh()
  if vim.fn.executable("rg") == 0 then
    set_popup_lines({
      "PROJECT HEALTH INSIGHTS (READ-ONLY)",
      string.rep("=", 78),
      "",
      "ripgrep (rg) is required for this dashboard.",
      "Install rg and run :ProjectHealth again.",
    })
    return
  end

  local cwd = vim.fn.getcwd()
  state.request_id = state.request_id + 1
  local request_id = state.request_id

  set_popup_lines({
    "PROJECT HEALTH INSIGHTS (READ-ONLY)",
    string.rep("=", 78),
    "",
    "Collecting workspace health metrics for monorepo targets...",
    "Analyzing frontend/backend/docker scopes using configured toolchains.",
  })

  local started = uv.hrtime()
  local payload = {
    cwd = cwd,
    footprint = {},
    eslint = {},
    tsc = {},
    ruff = {},
    hadolint = {},
    runtime_errors = {},
    elapsed_ms = 0,
  }

  local pending = 5
  local function complete_one()
    pending = pending - 1
    if pending ~= 0 then
      return
    end

    payload.elapsed_ms = math.floor((uv.hrtime() - started) / 1000000)
    if request_id ~= state.request_id then
      return
    end
    if not buf_valid(state.bufnr) then
      return
    end

    set_popup_lines(build_dashboard(payload))
  end

  local function run_collector(name, collector, assign)
    local settled = false

    local function done(stats)
      if settled then
        return
      end
      settled = true
      assign(stats or {})
      complete_one()
    end

    local ok, err = xpcall(function()
      collector(cwd, done)
    end, debug.traceback)

    if not ok then
      payload.runtime_errors[#payload.runtime_errors + 1] = string.format("%s failed: %s", name, err)
      done({})
      return
    end

    vim.defer_fn(function()
      if settled then
        return
      end
      payload.runtime_errors[#payload.runtime_errors + 1] = string.format("%s timed out after 125s", name)
      done({})
    end, 125000)
  end

  run_collector("Footprint", collect_footprint, function(stats)
    payload.footprint = stats
  end)

  run_collector("ESLint", collect_eslint, function(stats)
    payload.eslint = stats
  end)

  run_collector("TypeScript", collect_tsc, function(stats)
    payload.tsc = stats
  end)

  run_collector("Ruff", collect_ruff, function(stats)
    payload.ruff = stats
  end)

  run_collector("Hadolint", collect_hadolint, function(stats)
    payload.hadolint = stats
  end)
end

function M.open()
  if state.popup and state.popup.winid and win_valid(state.popup.winid) and buf_valid(state.bufnr) then
    vim.api.nvim_set_current_win(state.popup.winid)
    M.refresh()
    return
  end

  local ok_popup, Popup = pcall(require, "nui.popup")
  if not ok_popup then
    vim.notify("nui.nvim is required for ProjectHealth dashboard", vim.log.levels.ERROR)
    return
  end

  local width = math.max(100, math.floor(vim.o.columns * 0.92))
  local height = math.max(28, math.floor(vim.o.lines * 0.88))

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Codebase Health Dashboard ",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = width,
      height = height,
    },
    win_options = {
      winblend = 0,
      winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title",
      wrap = false,
      cursorline = false,
      number = false,
      relativenumber = false,
      signcolumn = "no",
    },
  })

  popup:mount()

  state.popup = popup
  state.bufnr = popup.bufnr

  vim.bo[popup.bufnr].buftype = "nofile"
  vim.bo[popup.bufnr].bufhidden = "wipe"
  vim.bo[popup.bufnr].swapfile = false
  vim.bo[popup.bufnr].modifiable = false
  vim.bo[popup.bufnr].readonly = true
  vim.bo[popup.bufnr].filetype = "projecthealth"

  local map_opts = { noremap = true, silent = true, buffer = popup.bufnr }
  vim.keymap.set("n", "q", close_popup, map_opts)
  vim.keymap.set("n", "<Esc>", close_popup, map_opts)
  vim.keymap.set("n", "r", function()
    M.refresh()
  end, map_opts)

  M.refresh()
end

function M.setup()
  ensure_highlight_groups()

  vim.api.nvim_create_augroup("ProjectHealthHighlights", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "ProjectHealthHighlights",
    callback = ensure_highlight_groups,
  })

  vim.api.nvim_create_user_command("ProjectHealth", function()
    M.open()
  end, { desc = "Open codebase health insights dashboard" })

  vim.api.nvim_create_user_command("ProjectHealthRefresh", function()
    M.refresh()
  end, { desc = "Refresh health insights dashboard" })
end

return M
