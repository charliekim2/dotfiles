return {
	{
		"sainnhe/gruvbox-material",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("gruvbox-material")
			vim.cmd.set("background:dark")
		end,
	},
	{
		"olivercederborg/poimandres.nvim",
	},
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = { "rktjmp/lush.nvim" },
	},
}
