vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wrap = true
vim.opt.guicursor = "n-v-i-c:block-Cursor"
vim.opt.guicursor = "i:blinkon1"

local indent = function(opts)
	vim.opt.shiftwidth = tonumber(opts.fargs[1])
	vim.opt.tabstop = tonumber(opts.fargs[1])
end

vim.api.nvim_create_user_command("Indent", indent, { nargs = 1 })

vim.keymap.set("n", "<leader>ww", ":set wrap!<cr>", { desc = "Toggle line wrapping" })

vim.keymap.set("n", "<leader>hd", vim.diagnostic.hide, { desc = "Hide diagnostics" })

vim.keymap.set("n", "<leader>nh", ":noh<cr>", { desc = "Hide search highlighting" })

vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "v" }, "p", '"_dP', { desc = "Replace selection with clipboard" })
