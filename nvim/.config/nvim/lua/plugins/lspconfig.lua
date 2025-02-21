return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{
			"SmiteshP/nvim-navbuddy",
			dependencies = {
				"SmiteshP/nvim-navic",
				"MunifTanjim/nui.nvim",
			},
			opts = { lsp = { auto_attach = true } },
		},
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		-- import mason
		require("mason").setup()
		require("mason-lspconfig").setup()
		-- import lspconfig plugin
		local lspconfig = require("lspconfig")

		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Add new filetypes
		vim.filetype.add({ extension = { templ = "templ" } })

		require("mason-lspconfig").setup_handlers({
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
				})
			end,

			["htmx"] = function()
				lspconfig.htmx.setup({
					capabilities = capabilities,
					filetypes = { "html", "templ" },
				})
			end,
			["emmet_ls"] = function()
				lspconfig.emmet_ls.setup({
					capabilities = capabilities,
					filetypes = { "html", "css", "templ", "typescriptreact", "javascriptreact" },
				})
			end,
			["clangd"] = function()
				lspconfig.clangd.setup({
					capabilities = capabilities,
					filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }, -- exclude "proto"
				})
			end,
			["tailwindcss"] = function()
				lspconfig.tailwindcss.setup({
					capabilities = capabilities,
					filetypes = {
						"templ",
						"typescriptreact",
						"javascriptreact",
						"astro",
						"javascript",
						"typescript",
						"react",
						"html",
					},
					init_options = { userLanguages = { templ = "html" } },
				})
			end,
			["lua_ls"] = function()
				lspconfig.lua_ls.setup({
					capabilities = capabilities,
					settings = { -- custom settings for lua
						Lua = {
							-- make the language server recognize "vim" global
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								-- make language server aware of runtime files
								library = {
									[vim.fn.expand("$VIMRUNTIME/lua")] = true,
									[vim.fn.stdpath("config") .. "/lua"] = true,
								},
							},
						},
					},
				})
			end,
		})

		-- Gleam setup, as it is not available on Mason
		lspconfig.gleam.setup({})

		vim.g.zig_fmt_autosave = 0

		-- Global mappings.
		-- See `:help vim.diagnostic.*` for documentation on any of the below functions
		vim.keymap.set("n", "<leader>E", vim.diagnostic.open_float)
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
		vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

		-- Use LspAttach autocommand to only map the following keys
		-- after the language server attaches to the current buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Enable completion triggered by <c-x><c-o>
				vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, noremap = true, silent = true }
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
				vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
				vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
				vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
				vim.keymap.set("n", "<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, opts)
				vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<leader>F", function()
					vim.lsp.buf.format({ async = true })
				end, opts)
				vim.keymap.set("n", "<leader>nn", ":Navbuddy<cr>", { desc = "Open Navbuddy" })
			end,
		})
	end,
	lazy = true,
	event = { "BufReadPre", "BufNewFile" },
}
