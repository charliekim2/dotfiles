return {
	"saghen/blink.cmp",
	dependencies = { "rafamadriz/friendly-snippets" },
	build = "cargo build --release",

	opts = {
		keymap = {
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-l>"] = { "accept", "fallback" },
		},
	},
	opts_extend = { "sources.default" },
}
