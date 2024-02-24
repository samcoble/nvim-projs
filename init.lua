require "core"

vim.opt.shada = ""

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]
if custom_init_path then dofile(custom_init_path) end

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
require "plugins"

--[[ My personal shit after here ]]

vim.opt.swapfile = false -- doesn't work anyway

dofile(vim.api.nvim_get_runtime_file("EZ.lua", false)[1])
dofile(vim.api.nvim_get_runtime_file("CYPH.lua", false)[1])
CYPH_load_my_settings()
vim.api.nvim_command("autocmd VimEnter * lua EZ.menu_toggle('main')") -- auto open

local macros =
{
  brackets =
    { macro = CYPH_to_macro('0v_yo:ESC_CHAR:Vpr{o:ESC_CHAR:Vpr}k'), reg_char = 'o' },
  semicolon_endl =
    { macro = CYPH_to_macro('$a;:ESC_CHAR:'), reg_char = 'l' },
  clear_line =
    { macro = '0v$hd', reg_char = 'u' },
  select_to_end =
    { macro = 'v$hd', reg_char = 'e' },
  onelineit_comment =
    { macro = CYPH_to_macro('k$vF/hdj$a :ESC_CHAR:p'), reg_char = '9' },
  select_all =
    { macro = 'ggVG', reg_char = 'a' },
  inbracketcont =
    { macro = '}kkVj_%j', reg_char = 'i' },
  wrap_each =
    { macro = CYPH_to_macro(':s/\\(\\w.*\\)/\\1:LEFT::LEFT:'), reg_char = 'b' },
} CYPH_load_macros(macros)

-- s/\(\w.*\)/data[0] = "\1";

local kms = {
  { 'n', '<leader>pr', '<cmd>lua CYPH_bor(1)<Enter>', true, true },
  { 'n', '<leader>pb', '<cmd>lua CYPH_bor(0)<Enter>', true, true },
  { 'n', '<leader>i', ':Telescope live_grep<Enter>', true, true }, -- Live fucking grep
  { 'n', '<C-y>', '3<C-y>M', true, true }, -- demon sp33d
  { 'n', '<C-e>', '3<C-e>M', true, true }, -- demon sp33d
  { 'n', '<C-g>', '<cmd>lua CYPH_save_mark()<Enter>', true, true },
  { 'n', '<C-p>', '<cmd>lua EZ.menu_toggle("main")<Enter>', true, true },
  { 'n', '<leader><CR>', '<cmd>lua EZ.menu_toggle("marks")<Enter>', true, true },
} for _, m in ipairs(kms) do vim.api.nvim_set_keymap(m[1], m[2], m[3], { noremap = m[4], silent = m[5] }) end


EZ.make_window({
  name = 'main',
  maps = {
    ["k"] = "<cmd>lua EZ.menu_jump('up')<CR>",
    ["j"] = "<cmd>lua EZ.menu_jump('down')<CR>",
    ["<CR>"] = "<cmd>lua EZ.menu_return(CYPH_load_project, true, false)<CR>",
    ["<ESC>"] = "<cmd>lua EZ.menu_close_all('')<CR>"
  },
  padding = {1,1,1,1},
  get_data = CYPH_generate_project_info
})


EZ.make_window({
  name = 'marks',
  maps = {
    ["k"] = "<cmd>lua EZ.menu_jump('up')<CR>",
    ["j"] = "<cmd>lua EZ.menu_jump('down')<CR>",
    ["d"] = "<cmd>lua EZ.menu_return(CYPH_delete_mark, false, true)<CR>",
    ["<CR>"] = "<cmd>lua EZ.menu_return(CYPH_goto_mark, true, false)<CR>",
    ["<ESC>"] = "<cmd>lua EZ.menu_close_all('')<CR>"
  },
  padding = {1,1,1,1},
  get_data = CYPH_get_marks
})
