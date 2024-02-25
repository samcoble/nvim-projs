local default_open_icons = -- 
{
  ["html"] = "  ",
  ["py"] = "  ",
  ["cpp"] = "  ",
  ["js"] = "  ",
  ["txt"] = "  ",
  ["lua"] = "  ",
  ["bat"] = "  ",
  ["?"] = " ",
}

--------------------------------------------------------------------------------------------------#


function CYPH_send_cr(terminal_buffer)
    vim.cmd("buffer " .. terminal_buffer) -- Switch to the terminal buffer
    vim.cmd("norm! <CR>") -- Send <CR>
    vim.cmd("q!")
end


function CYPH_bor(mode)
    local current_directory = vim.fn.getcwd()
    local bat_file_path = current_directory .. "/bor.bat"
    local arguments = (mode == 1 and " -c r " or " -c b ")-- .. vim.loop.getpid()
    local command = ":split | terminal " .. bat_file_path .. arguments
    local term_buf = vim.fn.bufnr('%') -- Store the terminal buffer number

    vim.cmd(command)
    vim.defer_fn(function() -- Enter insert mode
        vim.cmd("startinsert")
    end, 50)

    vim.cmd("augroup TerminalLeave")
    vim.cmd("autocmd!")
    vim.cmd("autocmd BufLeave <buffer> lua if vim.fn.getbufvar(vim.fn.bufnr('%'), '&buftype') == 'terminal' then CYPH_send_cr(" .. term_buf .. ") end")
    vim.cmd("augroup END")
end ----------------------------------------------------------------------------------------------#


function CYPH_load_my_settings()

  for _, cmd in ipairs {
    'command! Loadmacros lua CYPH_load_macros()',
    'command! -nargs=1 Goto lua EZ.go_to_directory(tonumber(<args>))',
    'highlight CursorLine guibg=#333742',
    'set number relativenumber',
    'highlight! link Comment Normal',
    'highlight Visual guibg=#4e584e',
    'highlight Normal guibg=#1a1c2280',
    'set timeoutlen=100',
    'set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50\\,a:blinkwait700-blinkoff400-blinkon50-Cursor/lCursor\\,sm:block-blinkwait175-blinkoff150-blinkon175',
  } do vim.cmd(cmd) end

  -- 'highlight Normal guibg=#1a1c22',
  -- 'highlight Normal guibg=#111317',
  -- 'set guifont=ProggyVector:h9',
end ----------------------------------------------------------------------------------------------#


function CYPH_load_macros(m)
  for _,v in pairs(m) do vim.fn.setreg(v[1],CYPH_to_macro(v[2])) end
end ----------------------------------------------------------------------------------------------#


function CYPH_to_macro(input_string)
  local temp_str = string.gsub(input_string, ':LEFT:', vim.api.nvim_replace_termcodes('<Left>', true, false, true));
  return string.gsub(temp_str, ':ESC_CHAR:', vim.api.nvim_replace_termcodes('<Esc>', true, false, true))
end ----------------------------------------------------------------------------------------------#


function CYPH_get_icon(filename) -- .ext -> char icon
  return default_open_icons[filename:match("%.(%w+)$")] or default_open_icons["?"]
end ----------------------------------------------------------------------------------------------#


function CYPH_goto_buf_line(path, lineNumber)
  local bufferNumber = vim.fn.bufnr(path)
  if bufferNumber ~= -1 then -- Check if buffer path is already open
    vim.cmd(bufferNumber .. "buffer! | " .. (lineNumber or 1))
  else -- not open
    vim.cmd("edit " .. path)
    vim.cmd((lineNumber and "normal! " .. lineNumber .. "G" or "normal! 1G"))
  end
end ----------------------------------------------------------------------------------------------#


-- Non EZ function
function CYPH_load_project(m_d)
  if m_d then
    EZ.go_to_directory(m_d.cursor)
  end
end ----------------------------------------------------------------------------------------------#


-- Non EZ function
function CYPH_goto_mark(m_d)
  local jump_line = m_d.raw[m_d.region].marks[m_d.new_cursor]
  local path = m_d.raw[m_d.region].path
  CYPH_goto_buf_line(path, jump_line)
  vim.cmd('norm! zz')
end ----------------------------------------------------------------------------------------------#


function CYPH_delete_mark(m_d)
  table.remove(m_d.raw[m_d.region].marks, m_d.new_cursor)
  table.remove(m_d.raw[m_d.region].names, m_d.new_cursor)
  local i_marks = #(m_d.raw[m_d.region].marks)
  if i_marks == 0 then
    table.remove(m_d.raw, m_d.region)
  end
  EZ.write_table_file(m_d.raw, 'cwd', '/hax_marks.txt')
end ----------------------------------------------------------------------------------------------#


function CYPH_save_mark()
  local max_line_length = 300

  local table_data = EZ.read_table_file('cwd', '/hax_marks.txt')

  local current_buffer = vim.fn.bufnr('%')
  local buffer_file = vim.fn.fnamemodify(vim.fn.bufname(current_buffer), ':p')
  local line_content = vim.fn.getline('.')
  local line_number = vim.fn.line('.')

  local path_exists = false
  for _, entry in ipairs(table_data) do
    if entry.path == buffer_file then
      -- Find the correct position to insert the mark based on line number
      local insert_index = 1
      for i, mark in ipairs(entry.marks) do
        if line_number < mark then break end
        insert_index = i + 1
      end
      table.insert(entry.marks, insert_index, line_number)
      entry.names = entry.names or {}
      table.insert(entry.names, insert_index, line_content:gsub("^%s+", ""):sub(1, max_line_length))
      path_exists = true
      break
    end
  end

  -- If the path doesn't exist, create a new entry
  if not path_exists then
    table.insert(table_data, { path = buffer_file, marks = { line_number }, names = { [1] = line_content:gsub("^%s+", ""):sub(1, max_line_length) } })
  end

  if EZ.write_table_file(table_data, 'cwd', '/hax_marks.txt') then
    print("Data saved successfully to file: /hax_marks.txt")
  end
end ----------------------------------------------------------------------------------------------#


function CYPH_generate_project_info()

  local result, jumps = {}, {}
  local track, indent = 1,'   '
  local table_data = EZ.read_table_file('root', '/hax_projects.txt');

  -- Generate content & jump map
  for i, entry in ipairs(table_data) do
    if i ~= 1 then
      table.insert(result, '')
      track = track + 1
    end

    table.insert(result, indent .. "[" .. i .. "]     '" .. entry.path .. "'")
    track = track + 1
    table.insert(jumps, track)

    if entry.files and type(entry.files) == 'table' then
      table.insert(result, indent .. "      │")
      track = track + 1

      for j, filename in ipairs(entry.files) do
        local line = indent .. '      ├─ ' .. CYPH_get_icon(filename) .. filename
        if j == #entry.files then
          line = indent .. '      └─ ' .. CYPH_get_icon(filename) .. filename
        end
        table.insert(result, line)
        track = track + 1
      end
    end
  end

  return {result,jumps,table_data,{}}
end ----------------------------------------------------------------------------------------------#


function CYPH_get_marks()

  local result, jumps, regions = {}, {}, {}
  local track, region, indent = 1, 0, '  '
  local table_data = EZ.read_table_file('cwd', '/hax_marks.txt')

  for i, entry in ipairs(table_data) do

    if next(entry.marks) ~= nil then

      region = region + #entry.marks
      table.insert(regions, region)

      if i ~= 1 then
        table.insert(result, "")
        track = track + 1
      end

      table.insert(result, entry.path)
      table.insert(result, "")
      track = track + 2

      for j, mark in ipairs(entry.marks) do
        local name = entry.names and entry.names[j] or "No Name"
        table.insert(result, indent .. mark .. ": " .. name)
        track = track + 1
        table.insert(jumps, track)
      end
    end
  end

  if #jumps == 0 then
    table.insert(result, "No marks :(")
  end

  return {result,jumps,table_data,regions}
end ----------------------------------------------------------------------------------------------#
