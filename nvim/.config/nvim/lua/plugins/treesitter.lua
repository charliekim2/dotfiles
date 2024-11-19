return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			-- import nvim-treesitter plugin
			local treesitter = require("nvim-treesitter.configs")

			-- TS folding
			vim.wo.foldmethod = "expr"
			vim.wo.foldlevel = 99
			vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

			-- configure treesitter
			treesitter.setup({ -- enable syntax highlighting

				ensure_installed = {
					"c",
					"python",
					"javascript",
					"java",
					"vimdoc",
					"lua",
				},

				disable = { "markdown" },

				highlight = {
					enable = true,
				},
				-- enable indentation
				indent = { enable = true },

				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<leader>g",
						node_incremental = ".",
						scope_incremental = false,
						node_decremental = ",",
					},
				},
			})
		end,
	},
}
