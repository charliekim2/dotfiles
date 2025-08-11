return {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			require("mason").setup({
				ensure_installed = { "lua_ls" },
			})

			vim.filetype.add({ extension = { templ = "templ" } }) -- Add templ filetype
			vim.g.zig_fmt_autosave = 0 -- Prevent zigfmt bug that writes shell startup to buffer
			vim.g.zig_fmt_parse_errors = 0

			local servers = {
				lua_ls = {},
				ts_ls = {},
				html = {},
				emmet_ls = {
					filetypes = { "html", "css", "templ", "typescriptreact", "javascriptreact" },
				},
				tailwindcss = {
					filetypes = {
						"templ",
						"typescriptreact",
						"javascriptreact",
						"javascript",
						"typescript",
						"react",
						"html",
					},
					init_options = { userLanguages = { templ = "html" } },
				},
				clangd = {},
				pyright = {},
				zls = {
					settings = {
						zls = {
							semantic_tokens = "partial",
							enable_build_on_save = true,
						},
					},
				},
				gopls = {},
				templ = {},
				htmx = {},
			}

			for server, config in pairs(servers) do
				vim.lsp.enable(server)
				config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
				vim.lsp.config(server, config)
			end

			vim.diagnostic.config({
				virtual_lines = true,
				underline = true,
			})

			vim.keymap.set("n", "<leader>E", vim.diagnostic.open_float)
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
			vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

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
				end,
			})
		end,
	},
}
