return {
	{
		"pineapplegiant/spaceduck",
		lazy = true,
		event = "ColorSchemePre",
	},
	{
		"rafi/awesome-vim-colorschemes",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("minimalist")
		end,
	},
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		lazy = true,
		event = "ColorSchemePre",
	},
}
