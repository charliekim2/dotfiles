return {
	"jpalardy/vim-slime",
	lazy = true,
	ft = { "python" },
	config = function()
		vim.g.slime_target = "tmux"
	end,
}
