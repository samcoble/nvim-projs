

-- 
local default_open_icons =
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

    local arguments
    if mode == 1 then arguments = " -c r" else arguments = " -c b" end

    local command = ":split | terminal " .. bat_file_path .. arguments
    local term_buf = vim.fn.bufnr('%') -- Store the terminal buffer number

    vim.cmd(command)
    vim.defer_fn(function() -- Enter insert mode
        vim.cmd("startinsert")
    end, 50)

    vim.cmd("augroup TerminalLeave")
    vim.cmd("autocmd!")
    vim.cmd("autocmd BufLeave <buffer> lua if vim.fn.getbufvar(vim.fn.bufnr('%'), '&buftype') == 'terminal' then CPYH_send_cr(" .. term_buf .. ") end")
    vim.cmd("augroup END")
end ----------------------------------------------------------------------------------------------#


function CYPH_load_macros(macros)
  for key, macro_data in pairs(macros) do
    vim.fn.setreg(macro_data.reg_char, macro_data.macro)
  end
end ----------------------------------------------------------------------------------------------#


function CYPH_load_my_settings()
  vim.cmd[[highlight CursorLine guibg=#333742]]
  vim.cmd[[set number relativenumber]]
  vim.cmd[[highlight! link Comment Normal]]
  vim.cmd('set guifont=ProggyVector:h9')
  vim.cmd[[highlight Visual guibg=#4e584e]]
  vim.cmd[[set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50\,a:blinkwait700-blinkoff400-blinkon50-Cursor/lCursor\,sm:block-blinkwait175-blinkoff150-blinkon175]]

  -- vim.cmd[[highlight Normal guibg=#1a1c22]]
  vim.cmd('highlight Normal guibg=#1a1c2280')
  -- vim.cmd[[highlight Normal guibg=#111317]]
  vim.cmd[[set timeoutlen=100]]
end ----------------------------------------------------------------------------------------------#


function CYPH_to_macro(input_string)
  local temp_str = string.gsub(input_string, ':LEFT:', vim.api.nvim_replace_termcodes('<Left>', true, false, true));
  return string.gsub(temp_str, ':ESC_CHAR:', vim.api.nvim_replace_termcodes('<Esc>', true, false, true))
end ----------------------------------------------------------------------------------------------#


-- filename.ext -> .ext : return
function CYPH_get_icon(filename)
  local extension = filename:match("%.(%w+)$") or "?" -- Extracts the extension without the dot
  local return_string = default_open_icons[extension] or default_open_icons["?"] -- Default to unknown icon if extension is not found
  return return_string
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
function CPYH_goto_mark(m_d)
  local jump_line = m_d.raw[m_d.region].marks[m_d.new_cursor]
  local path = m_d.raw[m_d.region].path
  CYPH_goto_buf_line(path, jump_line)
end ----------------------------------------------------------------------------------------------#


function CPYH_delete_mark(m_d)
  table.remove(m_d.raw[m_d.region].marks, m_d.new_cursor)
  table.remove(m_d.raw[m_d.region].names, m_d.new_cursor)
  local i_marks = #(m_d.raw[m_d.region].marks)
  if i_marks == 0 then
    table.remove(m_d.raw, m_d.region)
  end
  -- print("Modified table data:", vim.inspect(m_d.raw))
  EZ.write_table_file(m_d.raw, 'cwd', '/hax_marks.txt')
end ----------------------------------------------------------------------------------------------#


function CPYH_save_mark()
  local max_line_length = 300

  local table_data = EZ.read_table_file('cwd', '/hax_marks.txt')

  -- Get the current buffer's filename and line content
  local current_buffer = vim.fn.bufnr('%')
  local buffer_file = vim.fn.fnamemodify(vim.fn.bufname(current_buffer), ':p')
  local line_content = vim.fn.getline('.')
  local line_number = vim.fn.line('.')

  -- Check if the path already exists in the data table
  local path_exists = false
  for _, entry in ipairs(table_data) do
    if entry.path == buffer_file then
      -- Find the correct position to insert the mark based on line number
      local insert_index = 1
      for i, mark in ipairs(entry.marks) do
        if line_number < mark then
          break
        end
        insert_index = i + 1
      end
      -- Insert the mark and its name at the correct position
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


function CPYH_generate_project_info()
  local result = {}
  local jumps = {}
  local track = 1
  local indent = '   '

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
        local line = indent .. '      ├─ ' .. Get_icon(filename) .. filename
        if j == #entry.files then
          line = indent .. '      └─ ' .. Get_icon(filename) .. filename
        end
        table.insert(result, line)
        track = track + 1
      end
    end
  end

  return {result,jumps,table_data,{}}
end ----------------------------------------------------------------------------------------------#


function CPYH_get_marks()

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

  -- print(vim.inspect({result,jumps,table_data,regions}))
  -- print(vim.inspect(regions))
  return {result,jumps,table_data,regions}
end ----------------------------------------------------------------------------------------------#

