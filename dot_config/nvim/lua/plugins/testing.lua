local function settings_root(path)
  local markers = { "settings.gradle.kts", "settings.gradle" }
  local found = vim.fs.find(markers, { path = path, upward = true })[1]
  return found and vim.fs.dirname(found) or nil
end

local function gradle_module_dir(path)
  local markers = { "build.gradle.kts", "build.gradle" }
  local found = vim.fs.find(markers, { path = path, upward = true })[1]
  return found and vim.fs.dirname(found) or nil
end

local function root_dir(path)
  return settings_root(path) or gradle_module_dir(path) or vim.fn.getcwd()
end

local function gradle_test_task(path)
  if path:match("/src/test/.*/eval/") then
    return "evalTest"
  end
  return "test"
end

local function package_name(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local pkg = line:match("^%s*package%s+([%w_.]+)")
    if pkg then
      return pkg
    end
  end
end

local function class_name(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local cls = line:match("^%s*class%s+([%w_]+)")
    if cls then
      return cls
    end
  end
  local name = vim.fn.expand("%:t:r")
  return name ~= "" and name or nil
end

local function line_indent(line)
  return #(line:match("^%s*") or "")
end

local function line_name(line)
  local patterns = {
    '^%s*"([^"]+)"%s*%b{}',
    '^%s*"([^"]+)"%s*{',
    "^%s*`([^`]+)`%s*%b{}",
    "^%s*`([^`]+)`%s*{",
    '^%s*[%w_]+%s*%(%s*"([^"]+)"%s*%)%s*%b{}',
    '^%s*[%w_]+%s*%(%s*"([^"]+)"%s*%)%s*{',
    '^%s*fun%s+`([^`]+)`%s*%(',
  }
  for _, pattern in ipairs(patterns) do
    local name = line:match(pattern)
    if name then
      return name
    end
  end
end

local function nearest_kotest_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor, false)
  local names = {}
  local last_indent = math.huge

  for i = #lines, 1, -1 do
    local line = lines[i]
    local name = line_name(line)
    if name then
      local indent = line_indent(line)
      if indent < last_indent then
        table.insert(names, 1, name)
        last_indent = indent
      end
    end
  end

  return #names > 0 and table.concat(names, " -- ") or nil
end

local state = {
  terminal_buf = nil,
  terminal_win = nil,
  tree_buf = nil,
  tree_items = {},
  tree_ns = vim.api.nvim_create_namespace("kotest-tree"),
  tree_prev_win = nil,
  tree_win = nil,
}

local function show_terminal(cmd, cwd)
  if state.terminal_win and vim.api.nvim_win_is_valid(state.terminal_win) then
    vim.api.nvim_set_current_win(state.terminal_win)
  else
    vim.cmd("botright 15split")
    state.terminal_win = vim.api.nvim_get_current_win()
  end
  vim.cmd("enew")
  state.terminal_buf = vim.api.nvim_get_current_buf()
  vim.bo[state.terminal_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(state.terminal_buf, "gradle-test://output")
  vim.notify("Running: " .. cmd, vim.log.levels.INFO)
  local job = vim.fn.termopen(cmd, { cwd = cwd })
  if job <= 0 then
    vim.notify("Failed to start Gradle test command", vim.log.levels.ERROR)
    return
  end
  vim.cmd("startinsert")
end

local function run_gradle_test(opts)
  local source_path = opts.path or vim.fn.expand("%:p")
  local file_dir = vim.fn.fnamemodify(source_path, ":h")
  local cwd = root_dir(file_dir)
  local task = gradle_test_task(source_path)
  local init_script = vim.fn.expand("~/.config/nvim/gradle/kotest-filter.init.gradle.kts")
  local command = "./gradlew --rerun-tasks -I " .. vim.fn.shellescape(init_script)
  if opts.filter then
    command = command .. " -Pkotest.filter.tests=" .. vim.fn.shellescape(opts.filter)
  end
  command = command .. " " .. task
  if opts.spec then
    command = command .. " --tests " .. vim.fn.shellescape(opts.spec)
  end
  show_terminal(command, cwd)
end

local function run_kotest_direct(spec, include, path)
  local source_path = path or vim.fn.expand("%:p")
  local file_dir = vim.fn.fnamemodify(source_path, ":h")
  local cwd = root_dir(file_dir)
  local init_script = vim.fn.expand("~/.config/nvim/gradle/kotest-filter.init.gradle.kts")
  local command = "./gradlew --rerun-tasks -I " .. vim.fn.shellescape(init_script)
  command = command .. " -Pkotest.direct.spec=" .. vim.fn.shellescape(spec)
  if include then
    command = command .. " -Pkotest.direct.include=" .. vim.fn.shellescape(include)
  end
  command = command .. " kotestDirect"
  show_terminal(command, cwd)
end

local function run_kotest_nearest()
  local bufnr = vim.api.nvim_get_current_buf()
  local pkg = package_name(bufnr)
  local cls = class_name(bufnr)
  if not cls then
    vim.notify("Could not determine Kotlin test class", vim.log.levels.ERROR)
    return
  end

  local nearest = nearest_kotest_name(bufnr)
  local class_target = pkg and (pkg .. "." .. cls) or cls
  local include = nearest and (class_target .. "/" .. nearest) or class_target
  if nearest then
    vim.notify("Running Kotest test: " .. class_target .. " / " .. nearest, vim.log.levels.INFO)
  else
    vim.notify("Running Kotest spec: " .. class_target, vim.log.levels.INFO)
  end
  run_kotest_direct(class_target, include, vim.fn.expand("%:p"))
end

local function run_kotest_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local pkg = package_name(bufnr)
  local cls = class_name(bufnr)
  if not cls then
    vim.notify("Could not determine Kotlin test class", vim.log.levels.ERROR)
    return
  end
  run_gradle_test({ path = vim.fn.expand("%:p"), spec = pkg and (pkg .. "." .. cls) or cls })
end

local function package_name_from_lines(lines)
  for _, line in ipairs(lines) do
    local pkg = line:match("^%s*package%s+([%w_.]+)")
    if pkg then
      return pkg
    end
  end
end

local function class_name_from_lines(lines, path)
  for _, line in ipairs(lines) do
    local cls = line:match("^%s*class%s+([%w_]+)")
    if cls then
      return cls
    end
  end
  return vim.fn.fnamemodify(path, ":t:r")
end

local function parse_kotest_file(path)
  local lines = vim.fn.readfile(path)
  local pkg = package_name_from_lines(lines)
  local cls = class_name_from_lines(lines, path)
  if not cls then
    return nil
  end

  local spec = pkg and (pkg .. "." .. cls) or cls
  local tests = {}
  local name_stack = {}
  local indent_stack = {}

  for lnum, line in ipairs(lines) do
    local name = line_name(line)
    if name then
      local indent = line_indent(line)
      while #indent_stack > 0 and indent <= indent_stack[#indent_stack] do
        table.remove(indent_stack)
        table.remove(name_stack)
      end
      table.insert(indent_stack, indent)
      table.insert(name_stack, name)
      table.insert(tests, {
        include = table.concat(name_stack, " -- "),
        lnum = lnum,
        name = name,
        path = path,
        spec = spec,
      })
    end
  end

  if #tests == 0 then
    return nil
  end

  return {
    path = path,
    relpath = vim.fn.fnamemodify(path, ":."),
    spec = spec,
    tests = tests,
  }
end

local function tree_open_source(item)
  local target_win = state.tree_prev_win
  if target_win and vim.api.nvim_win_is_valid(target_win) then
    vim.api.nvim_set_current_win(target_win)
  else
    vim.cmd("wincmd p")
  end
  vim.cmd("edit " .. vim.fn.fnameescape(item.path))
  vim.api.nvim_win_set_cursor(0, { item.lnum or 1, 0 })
end

local function current_source_path()
  local path = vim.fn.expand("%:p")
  if path ~= "" and not path:match("^kotest%-tree://") then
    return path
  end

  local prev_win = state.tree_prev_win
  if prev_win and vim.api.nvim_win_is_valid(prev_win) then
    local buf = vim.api.nvim_win_get_buf(prev_win)
    local prev_path = vim.api.nvim_buf_get_name(buf)
    if prev_path ~= "" and not prev_path:match("^kotest%-tree://") then
      return prev_path
    end
  end

  return path
end

local function tree_run_item(item)
  if item.kind == "spec" then
    run_gradle_test({ path = item.path, spec = item.spec })
    return
  end
  if item.kind == "test" then
    run_kotest_direct(item.spec, item.spec .. "/" .. item.include, item.path)
  end
end

local function tree_current_item()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  return state.tree_items[lnum]
end

local function tree_action_open()
  local item = tree_current_item()
  if not item then
    return
  end
  tree_open_source(item)
end

local function tree_action_run()
  local item = tree_current_item()
  if not item or item.kind == "file" then
    return
  end
  tree_run_item(item)
end

local function tree_close()
  if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
    vim.api.nvim_win_close(state.tree_win, true)
  end
end

local function render_kotest_tree()
  local path = state.tree_source_path or current_source_path()
  local spec = parse_kotest_file(path)
  local lines = {}
  local items = {}

  if spec then
    table.insert(lines, "KOTEST")
    items[#lines] = { kind = "header" }

    table.insert(lines, "")
    items[#lines] = { kind = "spacer" }

    table.insert(lines, "FILE  " .. spec.relpath)
    items[#lines] = {
      kind = "file",
      lnum = 1,
      path = spec.path,
      spec = spec.spec,
    }

    table.insert(lines, "SPEC  " .. spec.spec)
    items[#lines] = {
      kind = "spec",
      lnum = spec.tests[1] and spec.tests[1].lnum or 1,
      path = spec.path,
      spec = spec.spec,
    }

    for _, test in ipairs(spec.tests) do
      table.insert(lines, "  TEST  " .. test.include)
      items[#lines] = vim.tbl_extend("force", test, { kind = "test" })
    end
  else
    table.insert(lines, "No Kotest tests found in current file")
  end

  state.tree_items = items

  vim.bo[state.tree_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.tree_buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(state.tree_buf, state.tree_ns, 0, -1)
  for i, item in ipairs(items) do
    if item.kind == "header" then
      vim.api.nvim_buf_add_highlight(state.tree_buf, state.tree_ns, "Title", i - 1, 0, -1)
    elseif item.kind == "file" then
      vim.api.nvim_buf_add_highlight(state.tree_buf, state.tree_ns, "Directory", i - 1, 0, 4)
      vim.api.nvim_buf_add_highlight(state.tree_buf, state.tree_ns, "Comment", i - 1, 6, -1)
    elseif item.kind == "spec" then
      vim.api.nvim_buf_add_highlight(state.tree_buf, state.tree_ns, "Type", i - 1, 0, 4)
      vim.api.nvim_buf_add_highlight(state.tree_buf, state.tree_ns, "Identifier", i - 1, 6, -1)
    elseif item.kind == "test" then
      vim.api.nvim_buf_add_highlight(state.tree_buf, state.tree_ns, "Function", i - 1, 2, 6)
    end
  end
  vim.bo[state.tree_buf].modifiable = false
  vim.bo[state.tree_buf].filetype = "kotesttree"
end

local function open_kotest_tree()
  state.tree_source_path = current_source_path()
  state.tree_prev_win = vim.api.nvim_get_current_win()
  if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
    vim.api.nvim_set_current_win(state.tree_win)
  else
    vim.cmd("botright 42vsplit")
    state.tree_win = vim.api.nvim_get_current_win()
  end

  if not state.tree_buf or not vim.api.nvim_buf_is_valid(state.tree_buf) then
    state.tree_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.tree_buf].bufhidden = "wipe"
    vim.api.nvim_buf_set_name(state.tree_buf, "kotest-tree://summary")
    vim.keymap.set("n", "q", tree_close, { buffer = state.tree_buf, silent = true })
    vim.keymap.set("n", "R", render_kotest_tree, { buffer = state.tree_buf, silent = true })
    vim.keymap.set("n", "o", tree_action_open, { buffer = state.tree_buf, silent = true })
    vim.keymap.set("n", "<CR>", tree_action_open, { buffer = state.tree_buf, silent = true })
    vim.keymap.set("n", "r", tree_action_run, { buffer = state.tree_buf, silent = true })
  end

  vim.api.nvim_win_set_buf(state.tree_win, state.tree_buf)
  vim.bo[state.tree_buf].buftype = "nofile"
  vim.bo[state.tree_buf].swapfile = false
  vim.wo[state.tree_win].number = false
  vim.wo[state.tree_win].relativenumber = false
  vim.wo[state.tree_win].signcolumn = "no"
  vim.wo[state.tree_win].winfixwidth = true
  render_kotest_tree()
end

local function toggle_kotest_tree()
  if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
    tree_close()
  else
    open_kotest_tree()
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "<leader>ts", toggle_kotest_tree, desc = "Toggle Kotest Tree" },
      { "<leader>tr", run_kotest_nearest, desc = "Run Nearest Kotest" },
      { "<leader>tf", run_kotest_file, desc = "Run Current Kotest Spec" },
    },
  },
}
