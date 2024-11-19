return {
	"mfussenegger/nvim-dap",
	config = function()
		vim.keymap.set("n", "<leader>dk", function()
			require("dap").continue()
		end, { desc = "DAP continue" })
		vim.keymap.set("n", "<leader>dl", function()
			require("dap").run_last()
		end, { desc = "Run last debug" })
		vim.keymap.set("n", "<leader>b", function()
			require("dap").toggle_breakpoint()
		end, { desc = "Toggle DAP breakpoint" })
	end,
}
