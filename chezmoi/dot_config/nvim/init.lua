local global = vim.g
local o = vim.opt

o.number = true
o.relativenumber = true

local lazyconfig = vim.fn.stdpath("config") .. "/plugins/lazy"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if vim.loop.fs_stat(lazyconfig) then
	vim.opt.rtp:prepend(lazyconfig)
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "plugins" }, 
	},
	install = { colorscheme = { "solarized" } },
	checker = { enabled = true },
})
