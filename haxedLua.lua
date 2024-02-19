HAX_MENU_OPEN = false

 -- 
local default_open_icons =
{
  ["html"] = "  ",
  ["py"] = "  ",
  ["cpp"] = "  ",
  ["js"] = "  ",
  ["txt"] = "  ",
  ["lua"] = "  ",
  ["?"] = " ",
}

function HAX_to_macro(input_string)
    return string.gsub(input_string, ':ESC_CHAR:', vim.api.nvim_replace_termcodes('<Esc>', true, false, true))
end

local macros =
{
  brackets =
  { macro = HAX_to_macro('0v_yo:ESC_CHAR:Vpr{o:ESC_CHAR:Vpr}k'),
    reg_char = 'o' },

  semicolon_endl =
  { macro = HAX_to_macro('$a;:ESC_CHAR:'),
    reg_char = 'l' },

  clear_line = 
  { macro = '0v$hd',
    reg_char = 'u' },

  select_to_end = 
  { macro = 'v$h',
    reg_char = 'e' },

  select_all =
  { macro = 'ggVG',
    reg_char = 'a' },

  inbracketcont =
  { macro = '}kkVj_%j',
    reg_char = 'i' },

  select_block =
  { macro = '{V}',
    reg_char = 'b' }
}

function LoadMacros()
    for key, macro_data in pairs(macros) do
        vim.fn.setreg(macro_data.reg_char, macro_data.macro)
    end
end

function HAX_bor(mode)
  if mode then
    vim.cmd[[!bor.bat -c r]]
  else
    vim.cmd[[!bor.bat -c b]]
  end
end

function HAX_loadMySettings()
  vim.cmd[[highlight CursorLine guibg=#333742]]
  vim.cmd[[set number relativenumber]]
  vim.cmd[[highlight! link Comment Normal]]
  vim.cmd('set guifont=ProggyVector:h9')
  vim.cmd[[highlight Visual guibg=#4e584e]]
  vim.cmd[[set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50\,a:blinkwait700-blinkoff400-blinkon50-Cursor/lCursor\,sm:block-blinkwait175-blinkoff150-blinkon175]]

  vim.cmd[[highlight Normal guibg=#1a1c22]]
  -- vim.cmd[[highlight Normal guibg=#111317]]
  LoadMacros()
end

function HAX_updateMark()
    -- Get the current directory set in Neovim
    local current_directory = vim.fn.getcwd()
    local max_line_length = 300

    -- Construct the full file path
    local file_path = current_directory .. "/hax_marks.txt"

    -- Load existing data or initialize empty table
    local data = {}
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        data = content and load("return " .. content)() or {}
    end

    -- Get the current buffer's filename and line content
    local current_buffer = vim.fn.bufnr('%')
    local buffer_file = vim.fn.fnamemodify(vim.fn.bufname(current_buffer), ':p')
    local line_content = vim.fn.getline('.')
    local line_number = vim.fn.line('.')

    -- Check if the path already exists in the data table
    local path_exists = false
    for _, entry in ipairs(data) do
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
        table.insert(data, { path = buffer_file, marks = { line_number }, names = { [1] = line_content:gsub("^%s+", ""):sub(1, max_line_length) } })
    end

    -- Write the updated table back to the file
    file = io.open(file_path, "w")
    if not file then
        print("Error: Unable to open file for writing.")
        return
    end
    file:write(vim.inspect(data))
    file:close()

    print("Data saved successfully to file: " .. file_path)
end



function GoToLineInBuffer(path, lineNumber)
    -- Check if the buffer for the provided path is already open
    local bufferNumber = vim.fn.bufnr(path)
    if bufferNumber ~= -1 then
        -- Buffer is already open, switch to it and go to the specified line number
        vim.cmd(bufferNumber .. "buffer! | " .. (lineNumber or 1))
    else
        -- Buffer is not open, open it in the current window without splitting
        vim.cmd("edit " .. path)
        -- Go to the specified line number or line 1 if not provided
        vim.cmd((lineNumber and "normal! " .. lineNumber .. "G" or "normal! 1G"))
    end
end



function HAX_findLineNumberInMarks(fileName, lineNumber)
    -- Convert lineNumber to a number if it's a string
    lineNumber = tonumber(lineNumber)

    -- Get the current working directory
    local currentDirectory = vim.fn.getcwd()
    
    -- Construct the full file path
    local filePath = currentDirectory .. "/hax_marks.txt"

    -- Load existing data or initialize empty table
    local data = {}
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        data = content and load("return " .. content)() or {}
    else
        print("Error: Unable to open file for reading.")
        return
    end

    -- Normalize the provided file name for comparison
    local normalizedFileName = fileName:gsub("^%s+", ""):gsub("[/\\]+", "\\"):lower() -- Remove leading whitespace, convert slashes to backslashes, and make lowercase

    -- Search for the entry with the specified file name
    for _, entry in ipairs(data) do
        -- Normalize the file name from the table for comparison
        local normalizedEntryFileName = entry.path:gsub("^%s+", ""):gsub("[/\\]+", "\\"):lower() -- Remove leading whitespace, convert slashes to backslashes, and make lowercase
        -- Compare the normalized file names
        if normalizedEntryFileName == normalizedFileName then
            -- Found the file, now check if the line number exists in marks
            local marks = entry.marks
            -- Check if lineNumber is within the bounds of the marks array
            if lineNumber and lineNumber >= 1 and lineNumber <= #marks then
                -- Return the mark corresponding to the lineNumber
                return marks[lineNumber]
            else
                print("Error: Line number out of bounds.")
                return
            end
        end
    end

    print("Error: File name not found in the table.")
end




function HAX_removeEntryAtLineNumber(fileName, lineNumber)
    -- Convert lineNumber to a number if it's a string
    lineNumber = tonumber(lineNumber)

    -- Get the current working directory
    local currentDirectory = vim.fn.getcwd()

    -- Construct the full file path
    local filePath = currentDirectory .. "/hax_marks.txt"

    -- Load existing data or initialize empty table
    local data = {}
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        data = content and load("return " .. content)() or {}
    else
        print("Error: Unable to open file for reading.")
        return
    end

    -- Normalize the provided file name for comparison
    local normalizedFileName = fileName:gsub("^%s+", ""):gsub("[/\\]+", "\\"):lower() -- Remove leading whitespace, convert slashes to backslashes, and make lowercase

    -- Search for the entry with the specified file name
    for i, entry in ipairs(data) do
        -- Normalize the file name from the table for comparison
        local normalizedEntryFileName = entry.path:gsub("^%s+", ""):gsub("[/\\]+", "\\"):lower() -- Remove leading whitespace, convert slashes to backslashes, and make lowercase
        -- Compare the normalized file names
        if normalizedEntryFileName == normalizedFileName then
            -- Found the file, now check if the line number exists in marks
            local marks = entry.marks
            -- Check if lineNumber is within the bounds of the marks array
            if lineNumber and lineNumber >= 1 and lineNumber <= #marks then
                -- Remove the mark corresponding to the lineNumber
                table.remove(entry.marks, lineNumber)
                if entry.names and entry.names[lineNumber] then
                    table.remove(entry.names, lineNumber)
                end
                -- Rewrite the data back to the file
                file = io.open(filePath, "w")
                if file then
                    file:write(vim.inspect(data))
                    file:close()
                    print("Entry at line number " .. lineNumber .. " removed successfully.")
                else
                    print("Error: Unable to open file for writing.")
                end
                return
            else
                print("Error: Line number out of bounds.")
                return
            end
        end
    end

    print("Error: File name not found in the table.")
end


function HAX_get_marks()
    local result = {}
    local zeroIndent = '   '
    local hasMarks = false

    -- Get the current working directory
    local current_directory = vim.fn.getcwd()

    -- Construct the full file path
    local file_path = current_directory .. "/hax_marks.txt"

    -- Load existing data or initialize empty table
    local data = {}
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        data = content and load("return " .. content)() or {}
    end

    -- Iterate over the data and format the marks
    for i, entry in ipairs(data) do
        -- Check if marks exist for the entry
        if next(entry.marks) ~= nil then
            hasMarks = true
            -- Insert the path as the header
            table.insert(result, "")
            table.insert(result, zeroIndent .. entry.path)
            table.insert(result, "")

            -- Insert the marks with their corresponding index
            for j, mark in ipairs(entry.marks) do
                local name = entry.names and entry.names[j] or "No Name"
                table.insert(result, zeroIndent .. zeroIndent .. "[" .. j .. "] " .. mark .. ": " .. name)
            end
        end
    end

    table.insert(result, "")

    if not hasMarks then
        table.insert(result, "No marks")
    end

    return result
end


function HAX_update_paths_table(mode)
    -- Ensure mode is either 0 or 1
    if mode ~= 0 and mode ~= 1 then
        print("Error: Invalid mode. Mode must be 0 or 1.")
        return
    end

    local paths_table = {}

    -- Get the current working directory
    local cwd = vim.fn.getcwd()

    -- Construct the file path for the table
    local table_file = vim.fn.expand('%:p:h') .. '/hax_projects.txt'

    -- Load existing data or initialize empty table
    local file = io.open(table_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        paths_table = content and load("return " .. content)() or {}
    else
        print("Error: Could not open hax_projects.txt")
        return
    end

    -- Function to check if a path already exists in the table
    local function pathExists(path)
        for _, entry in ipairs(paths_table) do
            if entry.path == path then
                return true, entry -- Return the existing entry
            end
        end
        return false
    end

    -- Mode 0: Add current working directory to the table if not exists
    if mode == 0 then
        local path_found, path_entry = pathExists(cwd)
        if not path_found then
            table.insert(paths_table, {
                path = cwd:gsub("\\", "/"), -- Replace backslashes with forward slashes
                files = {}
            })
            path_entry = paths_table[#paths_table] -- Get the newly added entry
        end

        -- Update cwd_entry for mode 0
        cwd_entry = path_entry
    end

    -- Mode 1: Do nothing for now, it will be handled later

    -- Add open buffer paths to the table if not already exists
    if mode == 0 then
        local open_files = {} -- Store open buffer paths to avoid duplicates
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if vim.fn.filereadable(buf_name) == 1 then
                local rel_path = vim.fn.fnamemodify(buf_name, ':.')
                open_files[rel_path] = true -- Store open buffer paths
            end
        end
        for rel_path, _ in pairs(open_files) do
            if not vim.tbl_contains(cwd_entry.files, rel_path) then
                table.insert(cwd_entry.files, rel_path)
            end
        end
    end

    -- Update the table file with the modified table data
    local formatted_paths = {}
    for _, entry in ipairs(paths_table) do
        local files = table.concat(entry.files, '", "')
        local formatted_entry = '{\n' ..
                                    '\tpath = "' .. entry.path .. '",\n' ..
                                    '\tfiles = { "' .. files .. '" }\n' ..
                                '}'
        table.insert(formatted_paths, formatted_entry)
    end

    local file_content = "{\n" .. table.concat(formatted_paths, ",\n") .. "\n}"
    file = io.open(table_file, "w")
    if file then
        file:write(file_content)
        file:close()
    else
        print("Error: Could not write to hax_projects.txt")
    end
end




function HAX_generate_project_info()
    local result = {}
    local zeroIndent = '   '

    -- Get the directory of the init.lua file
    local init_lua_dir = vim.fn.fnamemodify(vim.fn.stdpath('config') .. '/init.lua', ':h')

    -- Construct path to hax_projects.txt
    local hax_projects_path = init_lua_dir .. "/hax_projects.txt"

    -- Load the file content
    local file = io.open(hax_projects_path, "r")
    if not file then
        print("Error loading hax_projects.txt: File not found")
        return {}
    end

    -- Read the file content and parse as Lua table
    local file_content = file:read("*all")
    file:close()

    local success, table_data = pcall(loadstring("return " .. file_content))
    if not success or type(table_data) ~= "table" then
        print("Error parsing hax_projects.txt: Invalid table format")
        return {}
    end

    -- Iterate over the table data and format the output
    for i, entry in ipairs(table_data) do
        table.insert(result, "")
        table.insert(result, zeroIndent .. "[" .. i .. "]     '" .. entry.path .. "'")

        -- Check if files exist for the entry
        if entry.files and type(entry.files) == "table" then
            table.insert(result, zeroIndent .. "      │")

            -- Iterate over the files and format their display
            for j, filename in ipairs(entry.files) do
                local line = zeroIndent .. "      ├─ " .. HAX_get_icon(filename) .. filename
                if j == #entry.files then
                    line = zeroIndent .. "      └─ " .. HAX_get_icon(filename) .. filename
                end
                table.insert(result, line)
            end
        end
    end

    table.insert(result, "") -- Empty line at the end

    return result
end




function set_popup_styles(popup_win)
    -- Define a highlight group for the entire popup window
    vim.api.nvim_command("highlight PopupWindowFull guifg=#DDD guibg=#202020")
    vim.api.nvim_command("highlight FloatBorder guifg=#202020 guibg=#181818")

    -- Apply the highlight group to the popup window
    vim.api.nvim_win_set_option(popup_win, "winhl", "Normal:PopupWindowFull,FloatBorder:FloatBorder")
end


-- filename.ext -> .ext : return
function HAX_get_icon(filename)
    local extension = filename:match("%.(%w+)$") or "?" -- Extracts the extension without the dot
    local return_string = default_open_icons[extension] or default_open_icons["?"] -- Default to unknown icon if extension is not found
    return return_string
end

-- Include nil values in the count
local function tableFullLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    for _, v in pairs(t) do
        if v == nil then
            count = count + 1
        end
    end
    return count
end
--
-- function GoToDirectory(x)
--   local totalPaths = tableFullLength(paths)
--   -- print("\nMoved to dir: " .. tostring(x) .. "\n")
--   if x <= totalPaths then
--     vim.cmd("cd " .. paths[x])
--     local filesToOpen = default_open[x]
--     if filesToOpen then
--       for _, filename in ipairs(filesToOpen) do
--         -- local fullpath = vim.fn.fnamemodify(filename, ":p")
--         -- local exists = vim.fn.filereadable(fullpath)
--         -- if exists == 1 then
--           vim.cmd("edit " .. filename)
--         -- end
--       end
--     end
--   end
-- end


function GoToDirectory(x)
    -- Get the directory of the init.lua file
    local init_lua_dir = vim.fn.fnamemodify(vim.fn.stdpath('config') .. '/init.lua', ':h')

    -- Construct path to hax_projects.txt
    local hax_projects_path = init_lua_dir .. "/hax_projects.txt"

    -- Load the file content
    local file = io.open(hax_projects_path, "r")
    if not file then
        print("Error: Could not open hax_projects.txt")
        return
    end

    -- Read the file content and parse as Lua table
    local file_content = file:read("*all")
    file:close()

    local success, paths_table = pcall(loadstring("return " .. file_content))
    if not success or type(paths_table) ~= "table" then
        print("Error: Failed to parse hax_projects.txt content")
        return
    end

    -- Select the path using the index x
    local selected_path = paths_table[x]
    if not selected_path then
        print("Error: Invalid index")
        return
    end

    -- Change directory to the selected path
    local path = selected_path.path
    if not path then
        print("Error: No path found for index " .. x)
        return
    end
    vim.cmd("cd " .. path)

    -- Open files in the selected path
    local files = selected_path.files
    if files and type(files) == "table" then
        for _, filename in ipairs(files) do
            vim.cmd("edit " .. filename)
        end
    end
end


function HAX_pathsAndFilesToArray()
    local result = {}
    local zeroIndent = '   '
    for i, path in ipairs(paths) do
        table.insert(result, "")
        table.insert(result, zeroIndent .. "[" .. i .. "]     '" .. path .. "'")
        local filesToOpen = default_open[i]
        if filesToOpen then
            table.insert(result, zeroIndent .. "      │")

        for j, filename in ipairs(filesToOpen) do
            local line
            local ext = HAX_get_icon(filename)
            if j < #filesToOpen then
                line = zeroIndent .. "      ├━ " .. ext .. filename
                print(filename)
            else
                line = zeroIndent .. "      └━ " .. ext .. filename
            end
            table.insert(result, line)
        end

        end
        table.insert(result, "") -- Empty line after each path
    end
    return result
end


-- function HAX_longest_string(strings)
--     local max_length = 0
--
--   for _, str in ipairs(strings) do
--       if type(str) == "string" then
--           local length = string.len(str)
--           if length > max_length then
--               max_length = length
--           end
--       end
--   end
--   -- print(max_length)
--   return max_length
-- end


function HAX_longest_string(newdat)
    local max_length = 0

    -- Find the longest string in the newdat table
    for _, str in ipairs(newdat) do
        if type(str) == "string" then
            local length = string.len(str)
            if length > max_length then
                max_length = length
            end
        end
    end
    
    return max_length
end




-- Define a function to create and display the popup window
function HAX_open_menu(selected_index, mode)
    local cursor_init = vim.api.nvim_win_get_cursor(0)[1];

    if HAX_MENU_OPEN then
        -- Close the menu if it's open
        HAX_MENU_OPEN = false
        vim.api.nvim_win_close(0, true)
        return
    else
        -- Open the menu if it's closed
        HAX_MENU_OPEN = true
    end


    -- Get the selectable items from the global variable 'paths'
    local newdat, height
    if mode==1 then
      -- newdat = HAX_pathsAndFilesToArray()
      newdat = HAX_generate_project_info()
      height = #newdat
    else
      -- newdat = HAX_pathsAndFilesToArray()
      newdat = HAX_get_marks()
      height = #newdat or 1
      -- print(vim.inspect(HAX_get_marks()))
    end

    local width = HAX_longest_string(newdat) + 5

    local borderchars = {
            {"", "FloatBorder"}, -- left border
            {"▄", "FloatBorder"}, -- right border
            {" ", "FloatBorder"}, -- top border
            {" ", "FloatBorder"}, -- bottom border
            {" ", "FloatBorder"}, -- top-left corner
            {"▀", "FloatBorder"}, -- top-right corner
            {"Ԫ", "FloatBorder"}, -- bottom-right corner
            {" ", "FloatBorder"}, -- bottom-left corner
        }

    -- Create the popup window
    local popup_opts = {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
        border = borderchars,
        focusable = true,
    }


    -- Open the popup window in the context of the current buffer
    local popup_buf = vim.api.nvim_create_buf(false, true)
    local popup_win = vim.api.nvim_open_win(popup_buf, true, popup_opts)

    set_popup_styles(popup_win)

    -- Set the content of the popup buffer to the paths
    vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, newdat)

  -- The menu struct

    -- Listen for the WinLeave event to close the popup window when it loses focus
    vim.api.nvim_exec([[
        augroup HAXMenuAutoClose
            autocmd!
            autocmd WinLeave <buffer> lua handle_close()
        augroup END
    ]], false)


    -- Define array to store locations of [ # ] pattern matches
    local locations = {}
    for i, line in ipairs(newdat) do
        if line:match("%[%s*(%d+)%s*%]") then
            table.insert(locations, i)
        end
    end

    -- Function to update cursor and highlight based on selected index
    local function update_popup_content()
      if #locations>0 then
        if selected_index < 1 then
            selected_index = #locations
        elseif selected_index > #locations then
            selected_index = 1
        end

        -- Move cursor to selected index
        vim.api.nvim_win_set_cursor(0, {locations[selected_index], 0}) --/ GPT you fix here right inside here fix fix 

        -- Highlight the selected line
        vim.api.nvim_buf_clear_namespace(popup_buf, -1, 0, -1)
        vim.api.nvim_buf_add_highlight(popup_buf, -1, 'Visual', locations[selected_index] - 1, 0, -1)
      end
    end

    -- Update content initially
      update_popup_content()


    _G.handle_close = function()
      HAX_MENU_OPEN = false
      vim.api.nvim_win_close(0, true)
    end


    -- Function to handle Enter keypress
    _G.handle_enter = function(markMod)
      if #locations==0 then
        handle_close()
        return
      end
        if mode == 1 then
            local line = newdat[locations[selected_index]]
            local number = line:match("%[%s*(%d+)%s*%]")
            if number then
                local index = tonumber(number)
                print("Selected path:", index)
                vim.opt.swapfile = false
                vim.api.nvim_win_close(0, true)
                GoToDirectory(index)
            else
                print("Error: Unable to determine index.")
                vim.api.nvim_win_close(0, true)
            end

        else
            local mark_line = newdat[locations[selected_index]]
            local mark_number = mark_line:match("%[%s*(%d+)%s*%]")
            if not mark_number then
                print("Error: Unable to determine mark number.")
                vim.api.nvim_win_close(0, true)
                return
            end

            local path_line = newdat[locations[selected_index] - tonumber(mark_number) - 1]
            local path = path_line:match("([^%[%]]+)")

            if path then
                -- print("Selected path:", path)
                -- print("Selected mark:", mark_number)
                -- print(HAX_findLineNumberInMarks(path, mark_number))
                vim.opt.swapfile = false
                vim.api.nvim_win_close(0, true)
                if markMod==1 then
                  GoToLineInBuffer(path, HAX_findLineNumberInMarks(path, mark_number))
                  vim.cmd[[normal! zz]]
                elseif markMod==2 then
                  HAX_removeEntryAtLineNumber(path, mark_number)
                  HAX_open_menu(selected_index,2)
                end
                -- print(HAX_findLineNumberInMarks(path, mark_number))
            else
                print("Error: Unable to determine path.")
            end
        end
    end

    -- Menu struct key binds

    -- Define autocmd to capture Enter keypress in the popup window
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', '<CR>', ':lua handle_enter(1)<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', 'd', ':lua handle_enter(2)<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', 'q', ':lua handle_close()<CR>', { noremap = true, silent = true })

    -- Define keymap to handle cursor movement with 'j' and 'k' keys
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', 'j', ':lua move_cursor("down")<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', 'k', ':lua move_cursor("up")<CR>', { noremap = true, silent = true })

    -- Define keymap to close the popup window when Escape key is pressed
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', '<Esc>', ':lua handle_close()<CR>', { noremap = true, silent = true })

    -- Define keymap to prevent Tab key from switching buffers
    vim.api.nvim_buf_set_keymap(popup_buf, 'n', '<Tab>', '<Nop>', { noremap = true, silent = true })

    -- Function to move cursor up or down
    _G.move_cursor = function(direction)
        if direction == "up" then
            selected_index = selected_index - 1
        elseif direction == "down" then
            selected_index = selected_index + 1
        end
        update_popup_content()
    end
end



