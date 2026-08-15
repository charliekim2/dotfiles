return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
	},
	config = function()
		require("nvim-treesitter").install({
			"lua",
			"go",
			"zig",
			"markdown",
			"markdown_inline",
		})

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				pcall(vim.treesitter.start, args.buf)
			end,
		})

		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

		local incsel = { bufnr = nil, nodes = {} }
		local function visual_select(node)
			local sr, sc, er, ec = node:range()
			vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
			vim.cmd("normal! v")
			local target_col = ec > 0 and ec - 1 or 0
			vim.api.nvim_win_set_cursor(0, { er + 1, target_col })
		end
		local function inc_init()
			local node = vim.treesitter.get_node()
			if not node then
				return
			end
			incsel = { bufnr = vim.api.nvim_get_current_buf(), nodes = { node } }
			visual_select(node)
		end
		local function inc_expand()
			if vim.api.nvim_get_current_buf() ~= incsel.bufnr or #incsel.nodes == 0 then
				return inc_init()
			end
			local parent = incsel.nodes[#incsel.nodes]:parent()
			if not parent then
				return
			end
			table.insert(incsel.nodes, parent)
			visual_select(parent)
		end
		local function inc_shrink()
			if #incsel.nodes <= 1 then
				return
			end
			table.remove(incsel.nodes)
			visual_select(incsel.nodes[#incsel.nodes])
		end
		vim.keymap.set("n", "gnn", inc_init, { desc = "Init selection" })
		vim.keymap.set("x", "grn", inc_expand, { desc = "Expand to parent node" })
		vim.keymap.set("x", "grm", inc_shrink, { desc = "Shrink to child node" })

		require("nvim-treesitter-textobjects").setup({
			select = { lookahead = true },
			move = { set_jumps = true },
		})
		local select = require("nvim-treesitter-textobjects.select")
		local move = require("nvim-treesitter-textobjects.move")
		local swap = require("nvim-treesitter-textobjects.swap")
		local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

		local function sel(q)
			return function()
				select.select_textobject(q, "textobjects")
			end
		end
		local function ns(q)
			return function()
				move.goto_next_start(q, "textobjects")
			end
		end
		local function ne(q)
			return function()
				move.goto_next_end(q, "textobjects")
			end
		end
		local function ps(q)
			return function()
				move.goto_previous_start(q, "textobjects")
			end
		end
		local function pe(q)
			return function()
				move.goto_previous_end(q, "textobjects")
			end
		end

		local xo = { "x", "o" }
		vim.keymap.set(xo, "a=", sel("@assignment.outer"), { desc = "Select outer part of an assignment" })
		vim.keymap.set(xo, "i=", sel("@assignment.inner"), { desc = "Select inner part of an assignment" })
		vim.keymap.set(xo, "l=", sel("@assignment.lhs"), { desc = "Select left hand side of an assignment" })
		vim.keymap.set(xo, "r=", sel("@assignment.rhs"), { desc = "Select right hand side of an assignment" })
		vim.keymap.set(xo, "aa", sel("@parameter.outer"), { desc = "Select outer part of a parameter/argument" })
		vim.keymap.set(xo, "ia", sel("@parameter.inner"), { desc = "Select inner part of a parameter/argument" })
		vim.keymap.set(xo, "ai", sel("@conditional.outer"), { desc = "Select outer part of a conditional" })
		vim.keymap.set(xo, "ii", sel("@conditional.inner"), { desc = "Select inner part of a conditional" })
		vim.keymap.set(xo, "al", sel("@loop.outer"), { desc = "Select outer part of a loop" })
		vim.keymap.set(xo, "il", sel("@loop.inner"), { desc = "Select inner part of a loop" })
		vim.keymap.set(xo, "af", sel("@call.outer"), { desc = "Select outer part of a function call" })
		vim.keymap.set(xo, "if", sel("@call.inner"), { desc = "Select inner part of a function call" })
		vim.keymap.set(xo, "am", sel("@function.outer"), { desc = "Select outer part of a method/function definition" })
		vim.keymap.set(xo, "im", sel("@function.inner"), { desc = "Select inner part of a method/function definition" })
		vim.keymap.set(xo, "ac", sel("@class.outer"), { desc = "Select outer part of a class" })
		vim.keymap.set(xo, "ic", sel("@class.inner"), { desc = "Select inner part of a class" })

		vim.keymap.set("n", "<leader>na", function()
			swap.swap_next("@parameter.inner")
		end, { desc = "Swap parameter with next" })
		vim.keymap.set("n", "<leader>nm", function()
			swap.swap_next("@function.outer")
		end, { desc = "Swap function with next" })
		vim.keymap.set("n", "<leader>pa", function()
			swap.swap_previous("@parameter.inner")
		end, { desc = "Swap parameter with previous" })
		vim.keymap.set("n", "<leader>pm", function()
			swap.swap_previous("@function.outer")
		end, { desc = "Swap function with previous" })

		local nxo = { "n", "x", "o" }
		vim.keymap.set(nxo, "]f", ns("@call.outer"), { desc = "Next function call start" })
		vim.keymap.set(nxo, "]m", ns("@function.outer"), { desc = "Next method/function def start" })
		vim.keymap.set(nxo, "]c", ns("@class.outer"), { desc = "Next class start" })
		vim.keymap.set(nxo, "]i", ns("@conditional.outer"), { desc = "Next conditional start" })
		vim.keymap.set(nxo, "]l", ns("@loop.outer"), { desc = "Next loop start" })
		vim.keymap.set(nxo, "]F", ne("@call.outer"), { desc = "Next function call end" })
		vim.keymap.set(nxo, "]M", ne("@function.outer"), { desc = "Next method/function def end" })
		vim.keymap.set(nxo, "]C", ne("@class.outer"), { desc = "Next class end" })
		vim.keymap.set(nxo, "]I", ne("@conditional.outer"), { desc = "Next conditional end" })
		vim.keymap.set(nxo, "]L", ne("@loop.outer"), { desc = "Next loop end" })
		vim.keymap.set(nxo, "[f", ps("@call.outer"), { desc = "Prev function call start" })
		vim.keymap.set(nxo, "[m", ps("@function.outer"), { desc = "Prev method/function def start" })
		vim.keymap.set(nxo, "[c", ps("@class.outer"), { desc = "Prev class start" })
		vim.keymap.set(nxo, "[i", ps("@conditional.outer"), { desc = "Prev conditional start" })
		vim.keymap.set(nxo, "[l", ps("@loop.outer"), { desc = "Prev loop start" })
		vim.keymap.set(nxo, "[F", pe("@call.outer"), { desc = "Prev function call end" })
		vim.keymap.set(nxo, "[M", pe("@function.outer"), { desc = "Prev method/function def end" })
		vim.keymap.set(nxo, "[C", pe("@class.outer"), { desc = "Prev class end" })
		vim.keymap.set(nxo, "[I", pe("@conditional.outer"), { desc = "Prev conditional end" })
		vim.keymap.set(nxo, "[L", pe("@loop.outer"), { desc = "Prev loop end" })

		vim.keymap.set(nxo, ";", ts_repeat_move.repeat_last_move)
		vim.keymap.set(nxo, ",", ts_repeat_move.repeat_last_move_opposite)
	end,
}
