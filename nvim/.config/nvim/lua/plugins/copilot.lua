return {
	"github/copilot.vim",
	config = function()
		vim.keymap.set("n", "<leader>ce", ":Copilot enable<cr>", { desc = "Enable Copilot" })
		vim.keymap.set("n", "<leader>cd", ":Copilot disable<cr>", { desc = "Disable Copilot" })
		vim.cmd(":Copilot disable")
	end,
}
