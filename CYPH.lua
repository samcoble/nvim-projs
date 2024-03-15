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

function CYPH_send_cr(terminal_buffer)
    vim.cmd("buffer " .. terminal_buffer) -- Switch to the terminal buffer
    vim.cmd("norm! <CR>") -- Send <CR>
    vim.cmd("q!")
end ----------------------------------------------------------------------------------------------#

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
    vim.cmd("autocmd BufLeave <buffer> lua if vim.fn.getbufvar(vim.fn.bufnr('%'), '&buftype') == 'terminal' then CYPH_send_cr("..term_buf..") end")
    vim.cmd("augroup END")
end ----------------------------------------------------------------------------------------------#

function CYPH_load_my_settings()

  for _, cmd in ipairs {
    'cd C:/Users/samco/',
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
  -- 'set guifont=ProggyVector:h9',
end ----------------------------------------------------------------------------------------------#

function CYPH_to_macro(s)
  local _t, _r = {
    [':E:'] = '<Esc>', [':T:'] = '<Tab>', [':C:'] = '<Ctrl>', [':S:'] = '<Shift>',
    [':L:'] = '<Left>', [':R:'] = '<Right>', [':U:'] = '<Up>', [':D:'] = '<Down>',
  }, s for k,v in pairs(_t) do _r = string.gsub(_r, k, vim.api.nvim_replace_termcodes(v, 1, 0, 1)) end return _r
end ----------------------------------------------------------------------------------------------#

function CYPH_load_macros(mode, filename)
  local m = EZ.read_table_file(mode, filename)
  for _,v in pairs(m) do vim.fn.setreg(v[1],CYPH_to_macro(v[2])) end
  print('Macro table re-loaded')
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

function CYPH_load_project(m_d)
  if m_d then
    EZ.go_to_directory(m_d.cursor)
  end
end ----------------------------------------------------------------------------------------------#

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
      local insert_index = 1
      for i, mark in ipairs(entry.marks) do -- insert mark based on line number
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

  if not path_exists then -- If no path create a new entry
    table.insert(table_data, { path = buffer_file, marks = { line_number }, names = { [1] = line_content:gsub("^%s+", ""):sub(1, max_line_length) } })
  end

  if EZ.write_table_file(table_data, 'cwd', '/hax_marks.txt') then
    print("Data saved successfully to file: /hax_marks.txt")
  end
end ----------------------------------------------------------------------------------------------#

CYPH = {} CYPH.data = {r = {}, t = 1, xyl = {}, re = {}, res = 0} CYPH.tracker = {
  insTxt = function(t,v,n) table.insert(t.r, v) if n==1 then table.insert(t.r,'') end t.t=t.t+n+1 end,
  insJmp = function(t,i,l) table.insert(t.xyl,{t.t, i, l}) end,
  insReg = function(t,e) t.res = t.res + e table.insert(t.re,t.res) end,
} ------------------------------------------------------------------------------------------------#

function CYPH_get_macros(fn)

  local _cy = EZ.cloneOpts(CYPH.data)
  local t_d,_tr = EZ.read_table_file(fn[1], fn[2]), CYPH.tracker -- table data

  if t_d then
    _tr.insTxt(_cy,'EZ Macro', 1)
    for _, macro in ipairs(t_d) do
      _tr.insTxt(_cy,macro[1]..', '..macro[2], 0)
      _tr.insJmp(_cy,0,vim.fn.strchars(macro[1])+0)
      _tr.insJmp(_cy,vim.fn.strchars(macro[1])+2,vim.fn.strchars(macro[2])-3) -- arbitrary
    end
  else table.insert(_tr.r, "EZ: Error loading file: "..fn[1]) end

  if #_cy.xyl == 0 then _tr.insTxt("No macros ;(", 0) end
  return {_cy.r,_cy.xyl,t_d,{}}
end ----------------------------------------------------------------------------------------------#

function CYPH_generate_project_info(fn)

  local _cy, indent = EZ.cloneOpts(CYPH.data), '  '
  local t_d,_tr = EZ.read_table_file(fn[1], fn[2]), CYPH.tracker -- table data

  for i, entry in ipairs(t_d) do -- Generate content & jump map
    if i ~= 1 then _tr.insTxt(_cy, '', 0) end

    _tr.insTxt(_cy, "    '" .. entry.path .. "'", 0)
    _tr.insJmp(_cy, 0, vim.fn.strchars(_cy.r[_cy.t-1])+4) -- jump points
    if entry.files and type(entry.files) == 'table' then
      _tr.insTxt(_cy, indent .. "│", 0)
      for j, filename in ipairs(entry.files) do
        local _s = (j == #entry.files) and indent..'└─ ' or indent..'├─ '
        _tr.insTxt(_cy, (_s..CYPH_get_icon(filename)..filename), 0)
      end
    end
  end

  return {_cy.r,_cy.xyl,t_d,{}}
end ----------------------------------------------------------------------------------------------#

function CYPH_get_marks(fn)

  local _cy, indent = EZ.cloneOpts(CYPH.data), '  '
  local t_d,_tr = EZ.read_table_file(fn[1], fn[2]), CYPH.tracker -- table data

  for i, entry in ipairs(t_d) do
    if next(entry.marks) ~= nil then
      _tr.insReg(_cy, #entry.marks) -- region
      if i ~= 1 then
        _tr.insTxt(_cy, '', 0)
      end
      _tr.insTxt(_cy, entry.path, 1)
      for j, mark in ipairs(entry.marks) do
        local name = entry.names and entry.names[j] or "No name"
        _tr.insTxt(_cy, indent .. mark .. ": " .. name, 0)
        _tr.insJmp(_cy, 1, vim.fn.strchars(_cy.r[_cy.t-1]))
      end
    end
  end

  if #_cy.xyl == 0 then _tr.insTxt(_cy, "No marks :(", 0) end
  return {_cy.r,_cy.xyl,t_d,_cy.re}
end ----------------------------------------------------------------------------------------------#
