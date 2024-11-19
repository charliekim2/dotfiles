return {
	-- Syntax will not work if markdown treesitter is installed!!!
	"vim-pandoc/vim-pandoc-syntax",
	ft = { "markdown" },
	dependencies = {
		"godlygeek/tabular",
		"vim-pandoc/vim-pandoc",
	},
	config = function()
		vim.cmd("let g:pandoc#modules#enabled = []")

		vim.keymap.set("v", "<leader>a|", ":Tab /|<cr>", { desc = "Align by pipe" })
		vim.keymap.set("v", "<leader>a:", ":Tab /:<cr>", { desc = "Align by colon" })
		vim.keymap.set("v", "<leader>a=", ":Tab /=<cr>", { desc = "Align by equals" })
	end,
	-- "preservim/vim-markdown",
	-- dependencies = {
	-- 	"godlygeek/tabular",
	-- },
}
