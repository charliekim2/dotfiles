return {
	"m4xshen/autoclose.nvim",
	config = function()
		require("autoclose").setup()
	end,
	event = "InsertEnter",
	lazy = true,
}
