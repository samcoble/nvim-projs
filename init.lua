require "core"

vim.opt.shada = ""

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]

if custom_init_path then
  dofile(custom_init_path)
end

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)
require "plugins"

-- My personal shit here

-- should auto edit anyway
vim.opt.swapfile = false


dofile(vim.api.nvim_get_runtime_file("haxedLua.lua", false)[1])

-- vim.cmd[[command! Gotomenu lua HAX_open_menu(1)]]
-- vim.cmd[[command! Nvimsettings lua GoToDirectory(2)]]

HAX_loadMySettings()

vim.cmd[[command! Loadmacros lua LoadMacros()]]
vim.cmd("command! -nargs=1 Goto lua GoToDirectory(tonumber(<args>))")
vim.keymap.set("n", "<C-p>", function() HAX_open_menu(1,1) end, { desc = "My fucking menu" })
vim.keymap.set("n", "<C-m>", function() HAX_open_menu(1,2) end, { desc = "My fucking menu" })

-- vim.api.nvim_command("autocmd VimEnter * lua HAX_open_menu(1)")
vim.api.nvim_set_keymap('n', '<C-g>', '<cmd>lua HAX_updateMark()<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<leader>pp', '<cmd>lua HAX_update_paths_table(0)<CR>', {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', '<leader>pr', '<cmd>lua HAX_bor(1)<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>pb', '<cmd>lua HAX_bor(0)<CR>', { noremap = true, silent = true })

-- Live fucking grep
vim.api.nvim_set_keymap('n', '<leader>i', ':Telescope live_grep<CR>', { noremap = true, silent = true })
