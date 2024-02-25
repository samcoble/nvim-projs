
-- Define a Lua module
EZ = {
  windows = {},
  current_window = '',
  initialized = false,
  def_opts =
  {
    relative = "editor",
    width = 90,
    height = 30,
    style = "minimal",
    col = (vim.o.columns - 90) / 2,
    row = (vim.o.lines - 30) / 2,
  }
}

--------------------------------------------------------------------------------------------------#

function EZ.read_table_file(mode, name) -- file name, 'root' or 'cwd'

  if mode == 'root' then
    local init_lua_dir = vim.fn.fnamemodify(vim.fn.stdpath('config') .. '/init.lua', ':h') -- init used for root
    local projects_table_dir = init_lua_dir .. name

    local file = io.open(projects_table_dir, 'r')
    if not file then print('EZ: Error loading ' .. name .. ': File not found') return {} end

    local file_content = file:read("*all") file:close()

    local success, table_data = pcall(loadstring('return ' .. file_content))
    if not success or type(table_data) ~= "table" then
      print('EZ: Error parsing ' .. name .. ': Invalid table format')
      return {}
    else return table_data end -- Final output of table

  elseif mode == 'cwd' then
    -- Get the current working directory & construct the full file path
    local current_directory = vim.fn.getcwd()
    local file_path = current_directory .. name

    local file = io.open(file_path, 'r')
    if file then
      local content = file:read('*all') file:close()
      return(content and load('return ' .. content)() or {}) -- Final output of table
    end
  end

  return {'EZ: Table data failed to load'} -- If function fails to return prior
end ----------------------------------------------------------------------------------------------#

function EZ.write_table_file(table_data, mode, name) -- file name, 'root' or 'cwd'

  local init_dir, file_path = '', ''

  if mode == 'root' then -- [[root]]
    init_dir = vim.fn.fnamemodify(vim.fn.stdpath('config') .. '/init.lua', ':h')
  elseif mode == 'cwd' then -- [[cwd]]
    init_dir = vim.fn.getcwd()
  end

  file_path = init_dir .. name

  local file = io.open(file_path, "w")
  if not file then
    print("Error: Unable to open file for writing.") return false
  end

  file:write(vim.inspect(table_data)) file:close()
  return true -- If function fails to return prior
end ----------------------------------------------------------------------------------------------#

function EZ.cloneOpts(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do
    res[k] = EZ.cloneOpts(v)
  end
  return res
end ----------------------------------------------------------------------------------------------#

function EZ.go_to_directory(x)
  paths_table = EZ.read_table_file('root', '/hax_projects.txt')

  local selected_path = paths_table[x]
  if not selected_path then print("Error: Invalid index") return end

  local path = selected_path.path
  if not path then print("Error: No path found for index " .. x) return end
  vim.cmd("cd " .. path)

  local files = selected_path.files
  if files and type(files) == "table" then
    for _, filename in ipairs(files) do vim.cmd("edit " .. filename) end
  end
end ----------------------------------------------------------------------------------------------#

-- Make buffer & corresponding data for automated functions
function EZ.make_window(wind) -- (name, maps, get_data)

  local buf = vim.api.nvim_create_buf(false, true) -- buffer per window (perma)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  EZ.windows[wind.name] =
  {
    buf = buf, menu_state = false, menu_id = nil,
    cursor = 1, jumps = {}, regions = {}, raw = {},
    get_data = wind.get_data, maps = wind.maps,
    style = EZ.cloneOpts(EZ.def_opts)
  }

  -- Optional padding
  EZ.windows[wind.name].padding = wind.padding and wind.padding or {0, 0, 0, 0}
end ----------------------------------------------------------------------------------------------#

-- Return table with all information. Can be read and set.
function EZ.get_window_table(name)
  if EZ.windows[name] then return EZ.windows[name] else return nil end
end ----------------------------------------------------------------------------------------------#

-- Mapping functions. Automated. Will work with defocus close to simplify.
function EZ.set_mappings(name)
  local buf, maps = EZ.get_window_table(name).buf, EZ.get_window_table(name).maps
  for key, cmd in pairs(maps) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, cmd, { noremap = true })
  end
end ----------------------------------------------------------------------------------------------#

function EZ.reset_mappings(name)
  local buf, maps = EZ.get_window_table(name).buf, EZ.get_window_table(name).maps
  for key, _ in pairs(maps) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, key, {})
  end
end ----------------------------------------------------------------------------------------------#

function EZ.menu_move_cursor(jump_line)
  vim.api.nvim_buf_clear_highlight(0, -1, 0, -1)
  vim.api.nvim_win_set_cursor(0, {jump_line, 0})
  vim.api.nvim_buf_add_highlight(0, -1, 'Visual', jump_line - 1, 0, -1)
end ----------------------------------------------------------------------------------------------#

function EZ.longest_string(table)
  local max_length = 0
  for _, str in ipairs(table) do
    if type(str) == "string" then
      local length = string.len(str)
      if length > max_length then max_length = length end
    end
  end
  return max_length
end ----------------------------------------------------------------------------------------------#

-- Open menu
function EZ.menu_open(name)
  if not EZ.initialized then EZ.init() end -- call init
  if EZ.get_window_table(name) then
    local menu_data = EZ.get_window_table(name) -- Window obj
    if menu_data then
      local buf = EZ.get_window_table(name).buf
      local style = EZ.get_window_table(name).style

      if EZ.get_window_table(name).get_data then
        local data_t = menu_data.get_data() -- Handle per window
        local data = data_t[1] -- Visual data is local here

        EZ.current_window = name
        menu_data.jumps, menu_data.raw, menu_data.regions = data_t[2], data_t[3], data_t[4]

        EZ.menu_set_lines(buf, data, menu_data.padding)
        local new_w, new_h = tonumber(EZ.longest_string(vim.api.nvim_buf_get_lines(buf, 0, -1, false))), #data
        style.col, style.row = (vim.o.columns - new_w) / 2, (vim.o.lines - 30) / 2
        style.width, style.height = new_w==0 and 1 or new_w, new_h==0 and 1 or new_h

      else
        EZ.menu_set_lines(buf,{'No data'}, {1,2,1,2}) -- default padding, not used yet...
        style.col, style.row = (vim.o.columns - 7) / 2, (vim.o.lines - 1) / 2
        style.width, style.height = 7, 1
      end

      EZ.set_mappings(name) -- set per window key mappings
      menu_data.menu_state = true -- set flag open
      menu_data.menu_id = vim.api.nvim_open_win(buf, true, style) -- window created & logged

      if #menu_data.jumps ~= 0 then
        local cursor = (menu_data.cursor > #menu_data.jumps) and menu_data.cursor-1 or menu_data.cursor
        menu_data.cursor = cursor -- update window's value too
        local pady_offset = menu_data.padding and menu_data.padding[1] or 0
        local open_jump_line = math.max(0, menu_data.jumps[cursor] + pady_offset - 1) -- resume cursor
        EZ.menu_move_cursor(open_jump_line)
      end
    end
  end
end ----------------------------------------------------------------------------------------------#

-- Navigate current window
function EZ.menu_jump(dir) -- direction

  local menu_data = EZ.get_window_table(EZ.current_window) -- Load info of currently open window
  if menu_data then
    if #menu_data.jumps > 1 then
      local d_y = dir=="up" and -1 or 1
      d_y = (menu_data.cursor+d_y)
      local d_j_khaled = d_y%#menu_data.jumps
      menu_data.cursor = d_y<1 and #menu_data.jumps or (d_j_khaled==0) and #menu_data.jumps or d_j_khaled
      -- menu_data.cursor = (menu_data.cursor+d_y)<1 and #menu_data.jumps or (menu_data.cursor+d_y)%#menu_data.jumps
    else menu_data.cursor = 1 end
    -- local pady_offset = menu_data.padding and menu_data.padding[1] or 0
    local jump_line = math.max(0, menu_data.jumps[menu_data.cursor] + menu_data.padding[1] - 1)
    EZ.menu_move_cursor(jump_line)
  end
end ----------------------------------------------------------------------------------------------#

-- Handle any selection
function EZ.menu_return(callback_fn, close_before_use_data, refresh)

  local menu_data = EZ.get_window_table(EZ.current_window) -- Load info of currently open window
  if menu_data and #menu_data.raw > 0 then -- if table {} do not run
    local cursor = menu_data.cursor
    if close_before_use_data then EZ.menu_close(EZ.current_window) end

    local region = 0
    for k, v in ipairs(menu_data.regions) do
      if cursor <= v then region = k break end
    end

    local new_cursor = cursor -- pass cursor default
    if #menu_data.regions > 0 then -- don't use if no regions
      new_cursor = region==1 and cursor or cursor-menu_data.regions[region-1]
    end

    callback_fn({
      cursor = cursor,
      new_cursor = new_cursor,
      region = region,
      regions = menu_data.regions,
      raw = menu_data.raw
    })

    if refresh then
      local current_window = EZ.current_window
      EZ.menu_close(current_window)
      EZ.menu_open(current_window)
    end
  end
end ----------------------------------------------------------------------------------------------#

-- Close menu
function EZ.menu_close(name)
  if EZ.get_window_table(name).menu_id ~= nil then
    EZ.get_window_table(name).menu_state = false
    EZ.reset_mappings(name)
    vim.api.nvim_win_close(EZ.get_window_table(name).menu_id, true)
    EZ.get_window_table(name).menu_id = nil
  end
end ----------------------------------------------------------------------------------------------#

-- Setup auto close on defocus
function EZ.init()
  vim.api.nvim_exec([[
        augroup OtherAutoClose
            autocmd!
            autocmd BufEnter <buffer> lua EZ.menu_close_all('')
        augroup END
    ]], false)
end ----------------------------------------------------------------------------------------------#

function EZ.menu_toggle(name)
  if EZ.get_window_table(name).menu_state then EZ.menu_close(name) else EZ.menu_open(name) end
  EZ.menu_close_all(name) -- Auto close : my prefs
end ----------------------------------------------------------------------------------------------#

-- Close only active to avoid invalid menu_id
function EZ.menu_close_all(name)
  for key, window in pairs(EZ.windows) do
    if window.menu_state == true and name ~= tostring(key) then EZ.menu_close(key) end
  end
end ----------------------------------------------------------------------------------------------#

-- Set content of window
function EZ.menu_set_lines(buf, content, padding)

  for key, value in pairs(content) do
    if string.len(content[key]) > 0 then
      content[key] = string.rep(' ', padding[4]) .. value .. string.rep(' ', padding[2])
    end
  end

  for i = 1, padding[1] do table.insert(content, 1, '') end -- Pad top with new line
  for i = 1, padding[3] do table.insert(content, #content + 1, '') end -- Pad bottom with new line

  if buf then
    vim.api.nvim_buf_set_option(buf, "modifiable", true) -- [
    print("Content loaded.  RAND:" .. math.random(1, 100))
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content) -- entire window
    vim.api.nvim_buf_set_option(buf, "modifiable", false) -- ]
  end
end ----------------------------------------------------------------------------------------------#
