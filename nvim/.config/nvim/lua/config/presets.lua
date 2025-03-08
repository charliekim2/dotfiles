vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true

vim.cmd([[highlight iCursor guifg=white guibg=green]])
vim.cmd([[highlight vCursor guifg=white guibg=red]])
vim.opt.guicursor = "i:block-iCursor-blinkon1"
vim.opt.guicursor = vim.opt.guicursor + "v:block-vCursor"
vim.opt.guicursor = vim.opt.guicursor + "n-v-c:blinkon0"

vim.opt.termguicolors = true
vim.opt.foldenable = false
