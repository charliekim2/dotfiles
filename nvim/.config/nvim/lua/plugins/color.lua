return {
	{
		"norcalli/nvim-colorizer.lua",
		lazy = true,
		event = { "BufEnter" },
		config = function()
			require("colorizer").setup()
			vim.cmd("ColorizerAttachToBuffer")
		end,
	},
	{
		"sainnhe/gruvbox-material",
		priority = 1000,
		config = function()
			vim.opt.background = "dark"
			vim.g.gruvbox_material_background = "hard"
			vim.g.gruvbox_material_foreground = "material"
			vim.g.gruvbox_material_enable_bold = 1
			vim.g.gruvbox_material_enable_italic = 1

			vim.cmd("colorscheme gruvbox-material")
		end,
	},
	{
		"olivercederborg/poimandres.nvim",
		priority = 1000,
	},
	{
		"zenbones-theme/zenbones.nvim",
		dependencies = { "rktjmp/lush.nvim" },
		priority = 1000,
	},
	{
		"fenetikm/falcon",
		priority = 1000,
	},
	{
		"marko-cerovac/material.nvim",
		priority = 1000,
	},
}
