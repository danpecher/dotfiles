local M = {}

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end

  local decode_ok, decoded =
    pcall(vim.json.decode, table.concat(lines, "\n"), { luanil = { object = true, array = true } })
  return decode_ok and decoded or nil
end

local function read_jsonl(path, limit)
  local ok, lines = pcall(vim.fn.readfile, path, "", limit or 200)
  if not ok then
    return {}
  end

  local items = {}
  for _, line in ipairs(lines) do
    local decode_ok, decoded = pcall(vim.json.decode, line, { luanil = { object = true, array = true } })
    if decode_ok and decoded then
      items[#items + 1] = decoded
    end
  end

  return items
end

local function stat_mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime and stat.mtime.sec or 0
end

local function clean_title(text)
  if type(text) == "table" then
    local parts = {}
    for _, part in ipairs(text) do
      if type(part) == "string" then
        parts[#parts + 1] = part
      elseif type(part) == "table" and type(part.text) == "string" then
        parts[#parts + 1] = part.text
      end
    end
    text = table.concat(parts, " ")
  end

  text = tostring(text or "")
  text = text:gsub("<ide_opened_file>.-</ide_opened_file>", "")
  text = text:gsub("<environment_context>.-</environment_context>", "")
  text = text:gsub("%s+", " ")
  text = vim.trim(text)

  if text == "" then
    return "untitled session"
  end

  return #text > 90 and (text:sub(1, 87) .. "…") or text
end

local function format_time(seconds)
  return seconds > 0 and os.date("%Y-%m-%d %H:%M", seconds) or "unknown time"
end

local function launch_terminal(command, cwd)
  vim.cmd("enew")
  if cwd and cwd ~= "" then
    vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  end

  local escaped = vim.tbl_map(vim.fn.shellescape, command)
  vim.cmd("terminal " .. table.concat(escaped, " "))
  vim.cmd("startinsert")
end

local function project_root()
  local ok, root = pcall(function()
    return LazyVim.root()
  end)

  root = ok and root or vim.fn.getcwd(0)
  return vim.fs.normalize(vim.fn.fnamemodify(root, ":p"))
end

local function is_project_session(cwd, root)
  if not cwd or cwd == "" then
    return false
  end

  cwd = vim.fs.normalize(vim.fn.fnamemodify(cwd, ":p"))
  return cwd == root or vim.startswith(cwd, root .. "/")
end

local function codex_title(path)
  for _, item in ipairs(read_jsonl(path, 120)) do
    if item.type == "response_item" and item.payload and item.payload.role == "user" then
      local content = item.payload.content
      if type(content) == "table" and content[1] then
        return clean_title(content[1].text or content[1].content or content[1])
      end
    elseif item.type == "event_msg" and item.payload and item.payload.type == "user_message" then
      return clean_title(item.payload.message or item.payload.text)
    end
  end

  return "untitled session"
end

local function codex_sessions(root)
  local home = vim.uv.os_homedir()
  local paths = vim.fn.glob(home .. "/.codex/sessions/**/*.jsonl", true, true)
  local items = {}

  for _, path in ipairs(paths) do
    local first = read_jsonl(path, 1)[1]
    local payload = first and first.type == "session_meta" and first.payload or nil
    if payload and payload.id and is_project_session(payload.cwd, root) then
      local mtime = stat_mtime(path)
      local cwd = payload.cwd or root

      local title = codex_title(path)

      items[#items + 1] = {
        provider = "codex",
        id = payload.id,
        title = title,
        cwd = cwd,
        mtime = mtime,
        label = ("codex · %s"):format(title),
        detail = format_time(mtime),
        command = { "codex", "resume", payload.id },
      }
    end
  end

  return items
end

local function claude_sessions(root)
  local home = vim.uv.os_homedir()
  local indexes = vim.fn.glob(home .. "/.claude/projects/**/sessions-index.json", true, true)
  local items = {}

  for _, path in ipairs(indexes) do
    local index = read_json(path)
    for _, entry in ipairs((index and index.entries) or {}) do
      if entry.sessionId and not entry.isSidechain and is_project_session(entry.projectPath, root) then
        local mtime = entry.fileMtime and math.floor(entry.fileMtime / 1000) or stat_mtime(entry.fullPath or "")
        local cwd = entry.projectPath or root
        local title = clean_title(entry.firstPrompt)

        items[#items + 1] = {
          provider = "claude",
          id = entry.sessionId,
          title = title,
          cwd = cwd,
          mtime = mtime,
          label = ("claude · %s"):format(title),
          detail = format_time(mtime),
          command = { "claude", "--resume", entry.sessionId },
        }
      end
    end
  end

  return items
end

function M.sessions()
  local root = project_root()
  local items = {}
  vim.list_extend(items, codex_sessions(root))
  vim.list_extend(items, claude_sessions(root))

  table.sort(items, function(a, b)
    return a.mtime > b.mtime
  end)

  return items
end

function M.pick()
  local items = M.sessions()
  if #items == 0 then
    vim.notify("No saved AI sessions found", vim.log.levels.INFO, { title = "AI Sessions" })
    return
  end

  vim.ui.select(items, {
    prompt = "Resume AI session:",
    format_item = function(item)
      return ("%s  %s"):format(item.label, item.detail)
    end,
  }, function(item)
    if item then
      launch_terminal(item.command, item.cwd)
    end
  end)
end

return M
