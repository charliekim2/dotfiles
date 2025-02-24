vim.keymap.set("n", "<leader>H", ":noh<cr>", )
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "v" }, "p", '"_dP', { desc = "Replace selection with clipboard" })
