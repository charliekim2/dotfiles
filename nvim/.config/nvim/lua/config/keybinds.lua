vim.g["diagnostics_active"] = true
function Toggle_diagnostics()
	if vim.g.diagnostics_active then
		vim.g.diagnostics_active = false
		vim.diagnostic.disable()
	else
		vim.g.diagnostics_active = true
		vim.diagnostic.enable()
	end
end

function Toggle_copilot()
	if vim.g.copilot_active then
		vim.notify("Disabling GitHub Copilot")
		vim.g.copilot_active = false
		vim.cmd("Copilot disable")
	else
		vim.notify("Enabling GitHub Copilot")
		vim.g.copilot_active = true
		vim.cmd("Copilot enable")
	end
end

vim.keymap.set("n", "<leader>xh", ":noh<cr>", { desc = "Hide search highlighting" })
vim.keymap.set("n", "<leader>xd", Toggle_diagnostics, { desc = "Toggle diagnostics" })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "v" }, "p", '"_dP', { desc = "Replace selection with clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>gc", Toggle_copilot, { desc = "Toggle GitHub Copilot" })
