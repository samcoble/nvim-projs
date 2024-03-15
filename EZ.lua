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
    if not file then return {'EZ: Error loading ' .. name} end

    local file_content = file:read("*all") file:close()

    local success, table_data = pcall(loadstring('return ' .. file_content)) -- fix??
    if not success or type(table_data) ~= "table" then
      print('EZ: Error parsing ' .. name .. ': Invalid table format')
      return {}
    else return table_data end -- Final output of table

  elseif mode == 'cwd' then
    local current_directory = vim.fn.getcwd()
    local file_path = current_directory .. name

    local file = io.open(file_path, 'r')
    if file then
      local content = file:read('*all') file:close()
      return(content and load('return ' .. content)() or {'EZ: Error loading ' .. name}) -- Final output of table
    end
  end

  return {'EZ: Invalid mode: "'..mode..'", did you misspell it?'} -- If function fails to return prior
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

function EZ.cloneOpts(t)
  if type(t) ~= 'table' then return t end
  local res = {}
  for k, v in pairs(t) do res[k] = EZ.cloneOpts(v) end
  return res
end ----------------------------------------------------------------------------------------------#

function EZ.go_to_directory(x)
  local paths_table = EZ.read_table_file('root', '/hax_projects.txt')

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

function EZ.make_window(wind) -- Make buffer & corresponding data for automated functions

  local buf = vim.api.nvim_create_buf(false, true) -- buffer per window (perma)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  EZ.windows[wind.name] =
  {
    buf = buf, menu_state = false, menu_id = nil,
    cursor = 1, jumps = {}, regions = {}, raw = {},
    get_data = wind.get_data, files = wind.files,
    maps = wind.maps, style = EZ.cloneOpts(EZ.def_opts),
    modifiable = wind.modifiable
  }
  EZ.edit_value = {value = '', filename = '', cursor = 0} -- log any value chosen to edit and source
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

function EZ.reset_mappings(name) -- Set all keymaps key to key
  local buf, maps = EZ.get_window_table(name).buf, EZ.get_window_table(name).maps
  for key, _ in pairs(maps) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, key, {})
  end
end ----------------------------------------------------------------------------------------------#

function EZ.menu_move_cursor(coord)
    vim.api.nvim_buf_clear_highlight(0, -1, 0, -1)
    vim.api.nvim_win_set_cursor(0, {coord[1], coord[2]})
    vim.api.nvim_buf_add_highlight(0, -1, 'Visual', coord[1] - 1, coord[2] - 0, coord[2] + coord[3] - 0)
end ----------------------------------------------------------------------------------------------#

function EZ.longest_string(table)
  local max_length = 0
  for _, str in ipairs(table) do
    if type(str) == "string" then if string.len(str) > max_length then max_length = string.len(str) end end
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

      if menu_data.get_data then
        local data_t = menu_data.files and menu_data.get_data(menu_data.files) or menu_data.get_data()
        local data = data_t[1] -- Visual data is local here

        EZ.current_window = name
        menu_data.jumps, menu_data.raw, menu_data.regions = data_t[2], data_t[3], data_t[4]

        EZ.menu_set_lines(buf, data, menu_data.padding, menu_data.modifiable)
        local new_w, new_h = tonumber(EZ.longest_string(vim.api.nvim_buf_get_lines(buf, 0, -1, false))), #data
        style.col, style.row = (vim.o.columns - new_w) / 2, (vim.o.lines - 30) / 2
        style.width, style.height = new_w==0 and 1 or new_w, new_h==0 and 1 or new_h

      else
        EZ.menu_set_lines(buf,{'No data'}, {1,2,1,2}, false) -- default padding, not used yet...
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
        local padx_offset = menu_data.padding and menu_data.padding[4] or 0
        local j_line = math.max(0, menu_data.jumps[cursor][1] + pady_offset - 1) -- resume cursor
        local j_col = menu_data.jumps[cursor][2]

        EZ.menu_move_cursor({j_line, j_col+padx_offset, j_col+menu_data.jumps[cursor][3]})
      end
    end
  end
end ----------------------------------------------------------------------------------------------#

-- Navigate current window
function EZ.menu_jump(dir, j) -- direction, jumps

  local menu_data = EZ.get_window_table(EZ.current_window) -- Load info of currently open window
  if menu_data then
    if #menu_data.jumps > 1 then
      local d_y = dir=="up" and -j or j
      d_y = (menu_data.cursor+d_y)
      local d_j_khaled = d_y%#menu_data.jumps
      menu_data.cursor = d_y<1 and #menu_data.jumps or (d_j_khaled==0) and #menu_data.jumps or d_j_khaled

    else menu_data.cursor = 1 end

        local pady_offset = menu_data.padding and menu_data.padding[1] or 0
        local padx_offset = menu_data.padding and menu_data.padding[4] or 0
        local j_line = math.max(0, menu_data.jumps[menu_data.cursor][1] + pady_offset - 1) -- resume cursor
        local j_col = menu_data.jumps[menu_data.cursor][2]

        EZ.menu_move_cursor({j_line, j_col+padx_offset, j_col+menu_data.jumps[menu_data.cursor][3]})
  end
end ----------------------------------------------------------------------------------------------#

-- Handle any selection
function EZ.menu_return(callback_fn, close_before_use_data, refresh)

  local menu_data = EZ.get_window_table(EZ.current_window) -- Load info of currently open window
  if menu_data then -- if table {} do not run -- and #menu_data.raw > 0
    local cursor, region = menu_data.cursor, 0
    if close_before_use_data then EZ.menu_close(EZ.current_window) end

    for k, v in ipairs(menu_data.regions) do if cursor <= v then region = k break end end

    local new_cursor = cursor -- pass cursor default
    if #menu_data.regions > 0 then -- don't use if no regions
      new_cursor = region==1 and cursor or cursor-menu_data.regions[region-1]
    end

    callback_fn({
      cursor = cursor,
      new_cursor = new_cursor,
      region = region,
      regions = menu_data.regions,
      raw = menu_data.raw and menu_data.raw or {},
      files = menu_data.files and menu_data.files or {}
    })

    if refresh then EZ.menu_refresh() end
  end
end ----------------------------------------------------------------------------------------------#

function EZ.menu_refresh()
  EZ.menu_close(EZ.current_window)
  EZ.menu_open(EZ.current_window)
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

  vim.api.nvim_exec([[
    augroup CustomCommandListener
        autocmd!
        autocmd CmdlineEnter : lua EZ.menu_close_all('')
    augroup END
  ]], false) -- temp fix
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
function EZ.menu_set_lines(buf, content, padding, modifiable)

  for key, value in pairs(content) do
    if string.len(content[key]) > 0 then
      content[key] = string.rep(' ', padding[4]) .. value .. string.rep(' ', padding[2])
    end
  end

  for _ = 1, padding[1] do table.insert(content, 1, '') end -- Pad top with new line
  for _ = 1, padding[3] do table.insert(content, #content + 1, '') end -- Pad bottom with new line

  if buf then
    vim.api.nvim_buf_set_option(buf, "modifiable", true) -- [
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content) -- entire window
    vim.api.nvim_buf_set_option(buf, "modifiable", modifiable and modifiable or false)  -- ]
  end
end ----------------------------------------------------------------------------------------------#

function EZ.menu_edit_return(d)

  EZ.get_window_table('editor').raw = d.raw
  EZ.menu_open('editor')
  EZ.edit_value.value = d.raw[(d.cursor+d.cursor%2)/2][(1+d.cursor)%2+1]
  EZ.edit_value.source = d.files[1]
  EZ.edit_value.filename = d.files[2]
  EZ.edit_value.cursor = d.cursor
end ----------------------------------------------------------------------------------------------#

function EZ.menu_set_value() -- everything degenerated here must fix later : should use grid {r,c}
  local buf, new = EZ.get_window_table('editor').buf, ''
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do -- remove whitespace
    for char in line:gmatch("%S") do new = new .. char end
  end
  local t_d = EZ.read_table_file(EZ.edit_value.source, EZ.edit_value.filename)
  t_d[(EZ.edit_value.cursor+EZ.edit_value.cursor%2)/2][(1+EZ.edit_value.cursor)%2+1] = new
  EZ.write_table_file(t_d, EZ.edit_value.source, EZ.edit_value.filename)
end ----------------------------------------------------------------------------------------------#

function EZ.menu_get_value()
  return {{EZ.edit_value.value},{{2,0,0}},EZ.get_window_table('editor'),{}}
end ----------------------------------------------------------------------------------------------#

function EZ.menu_new_value(n)
  local files = EZ.get_window_table(EZ.current_window).files
  local t_d = EZ.read_table_file(files[1], files[2])
  table.insert(t_d, n)
  EZ.write_table_file(t_d, files[1], files[2])
  EZ.menu_refresh()
end ----------------------------------------------------------------------------------------------#

function EZ.menu_remove_value()
  local t_d = EZ.get_window_table(EZ.current_window)
  if t_d and t_d.files then
    local files = t_d.files
    local f_d = EZ.read_table_file(files[1], files[2])
    table.remove(f_d, (t_d.cursor+t_d.cursor%2)/2)
    EZ.get_window_table(EZ.current_window).cursor = EZ.get_window_table(EZ.current_window).cursor - 2 -- cols
    EZ.write_table_file(f_d, files[1], files[2])
    EZ.menu_refresh()
  end
end ----------------------------------------------------------------------------------------------#
