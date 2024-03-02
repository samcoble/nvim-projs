require "core"
require("core.utils").load_mappings()
vim.opt.shada = ""

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]
if custom_init_path then dofile(custom_init_path) end

dofile(vim.g.base46_cache .. "defaults")
require "plugins"

--[[ My personal shit after here ]]

vim.opt.swapfile = false -- doesn't work anyway

dofile(vim.api.nvim_get_runtime_file("EZ.lua", false)[1])
dofile(vim.api.nvim_get_runtime_file("CYPH.lua", false)[1])

CYPH_load_my_settings()
vim.api.nvim_command("autocmd VimEnter * lua EZ.menu_toggle('main')") -- auto open
CYPH_load_macros('root', '/cyph_macros.txt')

for _, m in ipairs({
  { 'n', '<leader>pk', '<cmd>lua SendCtrlPlus()<Enter>', true, true },
  { 'n', '<leader>pr', '<cmd>lua CYPH_bor(1)<Enter>', true, true },
  { 'n', '<leader>pb', '<cmd>lua CYPH_bor(0)<Enter>', true, true },
  { 'n', '<leader>i', ':Telescope live_grep<Enter>', true, true }, -- Live fucking grep
  { 'n', '<C-y>', '6k', true, true }, -- demon sp33d
  { 'n', '<C-e>', '6j', true, true }, -- demon sp33d
  { 'n', '<C-k>', '<C-y>k', true, true },
  { 'n', '<C-j>', '<C-e>j', true, true },
  { 'n', '<C-g>', '<cmd>lua CYPH_save_mark()<Enter>', true, true },
  { 'n', '<C-p>', '<cmd>lua EZ.menu_toggle("main")<Enter>', true, true },
  { 'n', '<leader><CR>', '<cmd>lua EZ.menu_toggle("marks")<Enter>', true, true },
  { 'n', '<leader>mm', '<cmd>lua EZ.menu_toggle("macros")<Enter>', true, true },
}) do vim.api.nvim_set_keymap(m[1], m[2], m[3], { noremap = m[4], silent = m[5] }) end

EZ.make_window({
  name = 'main',
  maps = {
    ["k"] = "<cmd>lua EZ.menu_jump('up', 1)<CR>",
    ["j"] = "<cmd>lua EZ.menu_jump('down', 1)<CR>",
    ["<Tab>"] = "<Nop>",
    ["<CR>"] = "<cmd>lua EZ.menu_return(CYPH_load_project, true, false)<CR>",
    ["<ESC>"] = "<cmd>lua EZ.menu_close_all('')<CR>"
  },
  padding = {1,1,1,3},
  get_data = CYPH_generate_project_info,
  files = {'root', '/hax_projects.txt'},
  modifiable = false
})

EZ.make_window({
  name = 'marks',
  maps = {
    ["k"] = "<cmd>lua EZ.menu_jump('up', 1)<CR>",
    ["j"] = "<cmd>lua EZ.menu_jump('down', 1)<CR>",
    ["d"] = "<cmd>lua EZ.menu_return(CYPH_delete_mark, false, true)<CR>",
    ["<Tab>"] = "<Nop>",
    ["<CR>"] = "<cmd>lua EZ.menu_return(CYPH_goto_mark, true, false)<CR>",
    ["<ESC>"] = "<cmd>lua EZ.menu_close_all('')<CR>"
  },
  padding = {1,2,1,2},
  get_data = CYPH_get_marks,
  files = {'cwd', '/hax_marks.txt'},
  modifiable = false
})

EZ.make_window({
  name = 'editor',
  maps = {
    ["<Tab>"] = "<Nop>",
    ["j"] = "<cmd>lua EZ.menu_jump('down', 0)<CR>",
    ["k"] = "<cmd>lua EZ.menu_jump('down', 0)<CR>",
    ["<ESC>"] = "<cmd>lua EZ.menu_close_all('')<CR>",
    ["<CR>"] = "<cmd>lua EZ.menu_return(EZ.menu_set_value, true, false) CYPH_load_macros('root', '/cyph_macros.txt')<CR>",
  },
  padding = {1,10,1,10},
  get_data = EZ.menu_get_value,
  modifiable = true
})
   -- must be passed in??

EZ.make_window({
  name = 'macros',
  maps = {
    ["k"] = "<cmd>lua EZ.menu_jump('up', 2)<CR>",
    ["j"] = "<cmd>lua EZ.menu_jump('down', 2)<CR>",
    ["h"] = "<cmd>lua EZ.menu_jump('up', 1)<CR>",
    ["l"] = "<cmd>lua EZ.menu_jump('down', 1)<CR>",
    ["n"] = "<cmd>lua EZ.menu_new_value({'0', ':E:iHey:E:'})<CR>",
    ["<C-d>"] = "<cmd>lua EZ.menu_remove_value()<CR>",
    ["<CR>"] = "<cmd>lua EZ.menu_return(EZ.menu_edit_return, false, true)<CR>",
    ["<Tab>"] = "<Nop>",
    ["<ESC>"] = "<cmd>lua EZ.menu_close_all('')<CR>"
  },
  padding = {1,2,1,2},
  get_data = CYPH_get_macros,
  files = {'root', '/cyph_macros.txt'},
  modifiable = false
})
