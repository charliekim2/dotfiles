return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")
		local cowsay = string.format(
			[[
	___________________________________
/ It is %-30s\
\ %-36s/
	-----------------------------------
				 \   ^__^ 
					\  (oo)\_______
						 (__)\       )\/\
								 ||----w |
								 ||     ||
		]],
			os.date("%A, %d %B %Y"),
			"Go and write some code already!!"
		)

		-- Set header
		dashboard.section.header.val = vim.split(cowsay, "\n")

		-- Set menu
		dashboard.section.buttons.val = {
			dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
			dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>Telescope find_files<CR>"),
			dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("SPC zz", "󰁯  > Open Lazy plugin manager", "<cmd>Lazy<CR>"),
			dashboard.button("q", "  > Quit NVIM", "<cmd>qa<CR>"),
		}

		-- Send config to alpha
		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}
