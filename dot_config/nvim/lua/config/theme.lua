local M = {}

M.default = "kanagawa"
M.state_file = vim.fn.stdpath("config") .. "/lua/config/theme_state.lua"

local function read_state()
  local ok, state = pcall(dofile, M.state_file)
  if not ok or type(state) ~= "table" then
    return nil
  end
  return state
end

function M.get()
  local state = read_state()
  if type(state and state.colorscheme) == "string" and state.colorscheme ~= "" then
    return state.colorscheme
  end
  return M.default
end

function M.set(colorscheme)
  if type(colorscheme) == "string" and colorscheme ~= "" then
    vim.g.user_colorscheme = colorscheme
  end
end

function M.persist(colorscheme)
  if type(colorscheme) ~= "string" or colorscheme == "" then
    return false
  end

  local lines = {
    "return {",
    ("  colorscheme = %q,"):format(colorscheme),
    "}",
  }

  local ok, err = pcall(vim.fn.writefile, lines, M.state_file)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR, { title = "Theme persistence failed" })
    return false
  end

  M.set(colorscheme)
  return true
end

return M
