return {
	"williamboman/mason.nvim",
	dependencies = {
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"black",
				"lua_ls",
				"pyright",
				"pylint",
				"eslint_d",
				"stylua",
				"ts_ls",
				"emmet_ls",
				"html",
				"clangd",
				"prettier",
			},
		})
	end,
	lazy = true,
	event = "CmdlineEnter",
}
