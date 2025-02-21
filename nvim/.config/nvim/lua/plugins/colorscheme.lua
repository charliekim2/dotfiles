return {
	{
		"pineapplegiant/spaceduck",
		lazy = true,
		event = "ColorSchemePre",
	},
	{
		"rafi/awesome-vim-colorschemes",
		lazy = true,
		event = "ColorSchemePre",
	},
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("kanagawabones")
			vim.cmd.set("background:dark")
		end,
	},
}
