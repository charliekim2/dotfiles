return {
	"saghen/blink.cmp",
	dependencies = { "rafamadriz/friendly-snippets" },
	version = "1.*",

	opts = {
		keymap = {
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-l>"] = { "accept", "fallback" },
		},
		fuzzy = { implementation = "prefer_rust" },
	},
	opts_extend = { "sources.default" },
}
