return {
	"echasnovski/mini.nvim",
	version = false,
	lazy = true,
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("mini.ai").setup()
		require("mini.move").setup()
		require("mini.operators").setup()
		require("mini.splitjoin").setup()
		require("mini.align").setup()
		local miniclue = require("mini.clue")
		miniclue.setup({
			triggers = {
				-- Leader triggers
				{ mode = "n", keys = "<Leader>" },
				{ mode = "x", keys = "<Leader>" },

				-- Built-in completion
				{ mode = "i", keys = "<C-x>" },

				-- `g` key
				{ mode = "n", keys = "g" },
				{ mode = "x", keys = "g" },

				-- Marks
				{ mode = "n", keys = "'" },
				{ mode = "n", keys = "`" },
				{ mode = "x", keys = "'" },
				{ mode = "x", keys = "`" },

				-- Registers
				{ mode = "n", keys = '"' },
				{ mode = "x", keys = '"' },
				{ mode = "i", keys = "<C-r>" },
				{ mode = "c", keys = "<C-r>" },

				-- Window commands
				{ mode = "n", keys = "<C-w>" },

				-- `z` key
				{ mode = "n", keys = "z" },
				{ mode = "x", keys = "z" },

				-- `]` key
				{ mode = "n", keys = "]" },
				{ mode = "x", keys = "]" },

				-- `[` key
				{ mode = "n", keys = "[" },
				{ mode = "x", keys = "[" },

				-- Visual ai
				{ mode = "v", keys = "a" },
				{ mode = "v", keys = "i" },
			},

			clues = {
				{ mode = "n", keys = "<Leader>f", desc = "+Telescope" },
				{ mode = "n", keys = "<Leader>e", desc = "+Tree" },
				{ mode = "n", keys = "<Leader>n", desc = "+Swap Next" },
				{ mode = "n", keys = "<Leader>p", desc = "+Swap Previous" },
				{ mode = "n", keys = "<Leader>w", desc = "+Workspace" },
				miniclue.gen_clues.builtin_completion(),
				miniclue.gen_clues.g(),
				miniclue.gen_clues.marks(),
				miniclue.gen_clues.registers(),
				miniclue.gen_clues.windows(),
				miniclue.gen_clues.z(),
			},

			window = {
				delay = 200,
				config = {
					border = "single",
					width = 40,
				},
			},
		})
	end,
}
