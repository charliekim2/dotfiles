return {
	"gbprod/yanky.nvim",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
	keys = {
		vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)"),
		vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)"),
		vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)"),
		vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)"),

		vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)"),
		vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)"),
	},
}
