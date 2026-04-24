local M = {}

local ns = vim.api.nvim_create_namespace("ghost_twins")
local state = {}

local DEFAULT_CONFIG = {
  min_lines = 4,
  max_depth = 6,
  auto_scan = false,
  large_file_lines = 1000,
  block_types = {
    "function_declaration",
    "function_definition",
    "method_definition",
    "method_declaration",
    "constructor_declaration",
    "function_item",
    "if_statement",
    "for_statement",
    "for_in_statement",
    "for_of_statement",
    "while_statement",
    "repeat_statement",
    "do_statement",
    "switch_statement",
    "try_statement",
    "catch_clause",
    "block",
    "statement_block",
    "compound_statement",
    "class_definition",
    "class_body",
  },
}

local config = vim.deepcopy(DEFAULT_CONFIG)

local PALETTE = {
  { bg = "#2f2428", fg = "#ff8a8a" },
  { bg = "#243029", fg = "#70d99b" },
  { bg = "#222d36", fg = "#71b7ff" },
  { bg = "#322a1f", fg = "#ffc66d" },
  { bg = "#2a2635", fg = "#c6a6ff" },
  { bg = "#203235", fg = "#62d8df" },
  { bg = "#35252f", fg = "#ff92c2" },
  { bg = "#303022", fg = "#d2db74" },
}

local FUNCTION_SCOPE_TYPES = {
  function_declaration = true,
  function_definition = true,
  function_item = true,
  function_statement = true,
  local_function = true,
  method_definition = true,
  method_declaration = true,
  constructor_declaration = true,
  arrow_function = true,
  function_expression = true,
  lambda_expression = true,
  anonymous_function = true,
}

local function notify(message, level)
  vim.notify("ghost-twins.nvim: " .. message, level or vim.log.levels.INFO)
end

local function normalize_bufnr(bufnr)
  if bufnr == nil or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end

  return bufnr
end

local function is_loaded_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

local function list_to_set(list)
  local set = {}

  for _, value in ipairs(list or {}) do
    set[value] = true
  end

  return set
end

local function define_highlights()
  for index, color in ipairs(PALETTE) do
    vim.api.nvim_set_hl(0, "GhostTwinsBg" .. index, {
      bg = color.bg,
      default = false,
    })

    vim.api.nvim_set_hl(0, "GhostTwinsBorder" .. index, {
      fg = color.fg,
      bold = true,
      default = false,
    })
  end
end

local function node_line_count(node)
  local start_row, _, end_row, _ = node:range()
  return end_row - start_row + 1
end

local function get_line_length(bufnr, row)
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, row, row + 1, true)

  if not ok or not lines or not lines[1] then
    return 0
  end

  return #lines[1]
end

local function normalized_node_range(bufnr, node)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if line_count == 0 then
    return nil
  end

  local start_row, start_col, end_row, end_col = node:range()

  start_row = math.max(0, math.min(start_row, line_count - 1))
  end_row = math.max(start_row, math.min(end_row, line_count - 1))

  local start_line_length = get_line_length(bufnr, start_row)
  local end_line_length = get_line_length(bufnr, end_row)

  start_col = math.max(0, math.min(start_col, start_line_length))
  end_col = math.max(0, math.min(end_col, end_line_length))

  if end_row == start_row and end_col <= start_col then
    end_col = start_line_length
  elseif end_row > start_row and end_col == 0 then
    end_col = end_line_length
  end

  return start_row, start_col, end_row, end_col
end

local function child_count(node)
  local ok, count = pcall(node.child_count, node)

  if ok and count then
    return count
  end

  return 0
end

local function child_at(node, index)
  local ok, child = pcall(node.child, node, index)

  if ok then
    return child
  end

  return nil
end

local function fingerprint_node(node, depth, max_depth)
  local node_type = node:type()
  local count = child_count(node)

  if count == 0 or depth >= max_depth then
    return node_type
  end

  local parts = {}

  for index = 0, count - 1 do
    local child = child_at(node, index)

    if child then
      parts[#parts + 1] = fingerprint_node(child, depth + 1, max_depth)
    end
  end

  return node_type .. "(" .. table.concat(parts, ",") .. ")"
end

function M.fingerprint(node)
  return fingerprint_node(node, 0, config.max_depth)
end

local function parser_for_buffer(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local lang = filetype

  if vim.treesitter.language and vim.treesitter.language.get_lang then
    lang = vim.treesitter.language.get_lang(filetype) or filetype
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)

  if ok and parser then
    return parser
  end

  ok, parser = pcall(vim.treesitter.get_parser, bufnr)

  if ok and parser then
    return parser
  end

  return nil, "no Treesitter parser available for filetype '" .. filetype .. "'"
end

local function node_contains_row(node, row)
  local start_row, _, end_row, _ = node:range()
  return start_row <= row and row <= end_row
end

local function deepest_node_at_row(node, row)
  if not node_contains_row(node, row) then
    return nil
  end

  for index = 0, child_count(node) - 1 do
    local child = child_at(node, index)
    local match = child and deepest_node_at_row(child, row)

    if match then
      return match
    end
  end

  return node
end

local function cursor_row_for_buffer(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      return vim.api.nvim_win_get_cursor(win)[1] - 1
    end
  end

  return 0
end

local function current_function_subtree(bufnr, root)
  local row = cursor_row_for_buffer(bufnr)
  local node = deepest_node_at_row(root, row)

  while node do
    if FUNCTION_SCOPE_TYPES[node:type()] then
      return node
    end

    node = node:parent()
  end

  return root
end

local function collect_candidates(bufnr, root, block_type_set)
  local by_fingerprint = {}

  local function walk(node)
    local node_type = node:type()

    if block_type_set[node_type] and node_line_count(node) >= config.min_lines then
      local start_row, start_col, end_row, end_col = normalized_node_range(bufnr, node)

      if start_row then
        local fingerprint = fingerprint_node(node, 0, config.max_depth)
        local item = {
          fingerprint = fingerprint,
          type = node_type,
          start_row = start_row,
          start_col = start_col,
          end_row = end_row,
          end_col = end_col,
          lines = end_row - start_row + 1,
        }

        by_fingerprint[fingerprint] = by_fingerprint[fingerprint] or {}
        by_fingerprint[fingerprint][#by_fingerprint[fingerprint] + 1] = item
      end
    end

    for index = 0, child_count(node) - 1 do
      local child = child_at(node, index)

      if child then
        walk(child)
      end
    end
  end

  walk(root)
  return by_fingerprint
end

local function sort_by_position(left, right)
  if left.start_row ~= right.start_row then
    return left.start_row < right.start_row
  end

  if left.start_col ~= right.start_col then
    return left.start_col < right.start_col
  end

  if left.end_row ~= right.end_row then
    return left.end_row < right.end_row
  end

  return left.end_col < right.end_col
end

local function build_clone_groups(by_fingerprint)
  local groups = {}

  for fingerprint, items in pairs(by_fingerprint) do
    if #items > 1 then
      table.sort(items, sort_by_position)
      groups[#groups + 1] = {
        fingerprint = fingerprint,
        items = items,
      }
    end
  end

  table.sort(groups, function(left, right)
    return sort_by_position(left.items[1], right.items[1])
  end)

  local clones = {}

  for group_index, group in ipairs(groups) do
    group.index = group_index
    group.color_index = ((group_index - 1) % #PALETTE) + 1

    for item_index, item in ipairs(group.items) do
      item.group_index = group_index
      item.item_index = item_index
      item.group_size = #group.items
      item.color_index = group.color_index
      clones[#clones + 1] = item
    end
  end

  table.sort(clones, sort_by_position)
  return groups, clones
end

local function clear_extmarks(bufnr)
  if is_loaded_buffer(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
end

local function render_clone(bufnr, item)
  local bg_group = "GhostTwinsBg" .. item.color_index
  local border_group = "GhostTwinsBorder" .. item.color_index
  local start_label = string.format(
    " +-- ghost twin %d.%d/%d ",
    item.group_index,
    item.item_index,
    item.group_size
  )
  local end_label = string.format(" `-- ghost twin %d.%d ", item.group_index, item.item_index)

  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, item.start_row, item.start_col, {
    end_row = item.end_row,
    end_col = item.end_col,
    hl_group = bg_group,
    hl_eol = true,
    priority = 120,
  })

  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, item.start_row, 0, {
    virt_text = { { start_label, border_group } },
    virt_text_pos = "eol",
    priority = 130,
  })

  if item.end_row ~= item.start_row then
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, item.end_row, 0, {
      virt_text = { { end_label, border_group } },
      virt_text_pos = "eol",
      priority = 130,
    })
  end
end

local function render_clones(bufnr, clones)
  define_highlights()
  clear_extmarks(bufnr)

  for _, item in ipairs(clones) do
    render_clone(bufnr, item)
  end
end

function M.clear(bufnr, opts)
  opts = opts or {}
  bufnr = normalize_bufnr(bufnr)

  clear_extmarks(bufnr)
  state[bufnr] = nil

  if not opts.silent then
    notify("cleared clone highlights")
  end
end

function M.scan(bufnr, opts)
  opts = opts or {}
  bufnr = normalize_bufnr(bufnr)

  if not is_loaded_buffer(bufnr) then
    if not opts.silent then
      notify("buffer is not loaded", vim.log.levels.WARN)
    end

    return nil
  end

  local parser, parser_error = parser_for_buffer(bufnr)

  if not parser then
    clear_extmarks(bufnr)

    if not opts.silent then
      notify(parser_error, vim.log.levels.WARN)
    end

    return nil
  end

  local ok, trees = pcall(parser.parse, parser)

  if not ok or not trees or not trees[1] then
    clear_extmarks(bufnr)

    if not opts.silent then
      notify("failed to parse buffer with Treesitter", vim.log.levels.WARN)
    end

    return nil
  end

  local full_root = trees[1]:root()
  local root = full_root
  local scope = "buffer"

  if vim.api.nvim_buf_line_count(bufnr) > config.large_file_lines then
    root = current_function_subtree(bufnr, full_root)
    scope = root == full_root and "buffer" or "current function"
  end

  local block_type_set = list_to_set(config.block_types)
  local by_fingerprint = collect_candidates(bufnr, root, block_type_set)
  local groups, clones = build_clone_groups(by_fingerprint)

  render_clones(bufnr, clones)

  state[bufnr] = {
    groups = groups,
    clones = clones,
    scope = scope,
  }

  if not opts.silent then
    notify(string.format("found %d clone nodes in %d groups (%s scope)", #clones, #groups, scope))
  end

  return state[bufnr]
end

local function find_jump_target(clones, direction)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  if direction > 0 then
    for _, item in ipairs(clones) do
      if item.start_row > row or (item.start_row == row and item.start_col > col) then
        return item
      end
    end

    return clones[1]
  end

  for index = #clones, 1, -1 do
    local item = clones[index]

    if item.start_row < row or (item.start_row == row and item.start_col < col) then
      return item
    end
  end

  return clones[#clones]
end

local function jump(direction)
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_state = state[bufnr]

  if not buffer_state or not buffer_state.clones or #buffer_state.clones == 0 then
    buffer_state = M.scan(bufnr, { silent = true })
  end

  if not buffer_state or not buffer_state.clones or #buffer_state.clones == 0 then
    notify("no clones found", vim.log.levels.WARN)
    return
  end

  local target = find_jump_target(buffer_state.clones, direction)

  if not target then
    notify("no clones found", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_win_set_cursor(0, { target.start_row + 1, target.start_col })
  vim.cmd("normal! zv")
  notify(string.format("ghost twin %d.%d/%d", target.group_index, target.item_index, target.group_size))
end

function M.next()
  jump(1)
end

function M.prev()
  jump(-1)
end

local function create_commands()
  vim.api.nvim_create_user_command("GhostTwinsScan", function()
    M.scan(0)
  end, {
    desc = "Scan the current buffer for structural AST clones",
    force = true,
  })

  vim.api.nvim_create_user_command("GhostTwinsClear", function()
    M.clear(0)
  end, {
    desc = "Clear Ghost Twins clone highlights",
    force = true,
  })

  vim.api.nvim_create_user_command("GhostTwinsNext", function()
    M.next()
  end, {
    desc = "Jump to the next Ghost Twins clone",
    force = true,
  })

  vim.api.nvim_create_user_command("GhostTwinsPrev", function()
    M.prev()
  end, {
    desc = "Jump to the previous Ghost Twins clone",
    force = true,
  })
end

function M.setup(opts)
  opts = opts or {}

  local merged = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULT_CONFIG), opts)

  if opts.block_types then
    merged.block_types = vim.deepcopy(opts.block_types)
  end

  config = merged

  define_highlights()
  create_commands()

  local augroup = vim.api.nvim_create_augroup("GhostTwins", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = define_highlights,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    callback = function(args)
      state[args.buf] = nil
    end,
  })

  if config.auto_scan then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup,
      callback = function(args)
        if vim.bo[args.buf].buftype == "" then
          M.scan(args.buf, { silent = true })
        end
      end,
    })
  end

  return M
end

create_commands()

return M
