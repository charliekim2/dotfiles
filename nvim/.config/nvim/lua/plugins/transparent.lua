return {
	"xiyaowong/transparent.nvim",
	config = function()
		vim.keymap.set("n", "<leader>tt", ":TransparentToggle<cr>", { desc = "Toggle transparency" })
	end,
}
