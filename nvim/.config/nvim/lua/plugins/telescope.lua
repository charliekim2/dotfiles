return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			extensions = {
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					-- the default case_mode is "smart_case"
				},
			},
		})
		telescope.load_extension("fzf")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
		vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Telescope live grep" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
		vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope old files" })
		vim.keymap.set("n", "<leader>fc", builtin.command_history, { desc = "Telescope command history" })

		vim.keymap.set("n", "<leader>fq", builtin.quickfix, { desc = "Telescope quickfix" })
		vim.keymap.set("n", "<leader>fl", builtin.loclist, { desc = "Telescope loclist" })
		vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "Telescope jumplist" })
	end,
}
