return {
	"echasnovski/mini.nvim",
	version = false,
	config = function()
		-- Visual
		require("mini.statusline").setup()
		require("mini.trailspace").setup()
		require("mini.notify").setup()
		require("mini.diff").setup()

		-- Text modification
		require("mini.align").setup()
		require("mini.pairs").setup()
		require("mini.splitjoin").setup()
		require("mini.surround").setup()
		require("mini.comment").setup()
		require("mini.move").setup()

		-- Movement
		require("mini.ai").setup()
		require("mini.jump").setup()
		require("mini.bracketed").setup()

		-- Misc
		require("mini.operators").setup()
		require("mini.git").setup()
		require("mini.basics").setup({
			mappings = {
				windows = true,
			},
		})
	end,
}
