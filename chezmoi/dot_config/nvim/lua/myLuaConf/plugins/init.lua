-- luacheck: read globals vim

return {
	{
		"catppuccin",
		name = "catppuccin",
		priority = 1000,
		after = function(_)
			require("catppuccin").setup({
				flavour = "mocha",
				background = {
					light = "latte",
					dark = "mocha",
				},
				transparent_background = true,
				term_colors = true,
				dim_inactive = {
					enabled = false,
					shade = "dark",
					percentage = 0.15,
				},
				integrations = {
					blink_cmp = true,
					gitsigns = true,
					telescope = true,
					notify = true,
					mini = false,
					harpoon = true,
					which_key = true,
					indent_blankline = {
						enabled = true,
						colored_indent_levels = false,
					},
					native_lsp = {
						enabled = true,
					},
					treesitter = true,
					treesitter_context = true,
				},
			})
			vim.cmd.colorscheme("catppuccin")

			local C = require("catppuccin.palettes").get_palette()
			local mode_colors = {
				["n"] = { "NORMAL", C.blue },
				["no"] = { "N-PENDING", C.blue },
				["i"] = { "INSERT", C.green },
				["ic"] = { "INSERT", C.green },
				["t"] = { "TERMINAL", C.green },
				["v"] = { "VISUAL", C.mauve },
				["V"] = { "V-LINE", C.mauve },
				["\22"] = { "V-BLOCK", C.flamingo },
				["R"] = { "REPLACE", C.maroon },
				["Rv"] = { "V-REPLACE", C.maroon },
				["s"] = { "SELECT", C.maroon },
				["S"] = { "S-LINE", C.maroon },
				["\19"] = { "S-BLOCK", C.maroon },
				["c"] = { "COMMAND", C.peach },
				["cv"] = { "COMMAND", C.peach },
				["ce"] = { "COMMAND", C.peach },
				["r"] = { "PROMPT", C.teal },
				["rm"] = { "MORE", C.teal },
				["r?"] = { "CONFIRM", C.mauve },
				["!"] = { "SHELL", C.green },
			}

			local function dim_color(hex_color, dim_factor)
				hex_color = hex_color:gsub("^#", "")
				local r = tonumber(hex_color:sub(1, 2), 16)
				local g = tonumber(hex_color:sub(3, 4), 16)
				local b = tonumber(hex_color:sub(5, 6), 16)
				r = math.floor(r * dim_factor)
				g = math.floor(g * dim_factor)
				b = math.floor(b * dim_factor)
				return string.format("#%02x%02x%02x", r, g, b)
			end

			local function set_line_nr_color()
				local mode = vim.api.nvim_get_mode().mode
				local mode_info = mode_colors[mode]
				local mode_color = mode_info and mode_info[2] or C.text
				local dimmed = dim_color(mode_color, 0.65)
				vim.api.nvim_set_hl(0, "CursorLineNr", { fg = mode_color, bold = true })
				vim.api.nvim_set_hl(0, "LineNr", { fg = dimmed })
			end

			vim.api.nvim_create_augroup("ModeChangeLineNr", { clear = true })
			vim.api.nvim_create_autocmd("ModeChanged", {
				group = "ModeChangeLineNr",
				callback = set_line_nr_color,
			})
			set_line_nr_color()
		end,
	},
	-- {
	--   'nvim-notify',
	--   event = 'DeferredUIEnter',
	--   keys = {
	--     {
	--       '<Leader>un',
	--       function()
	--         require('notify').dismiss { silent = true, pending = true }
	--       end,
	--       desc = 'Dismiss all notifications (Notify)',
	--     },
	--   },
	--   after = function(_)
	--     vim.notify = require 'notify'
	--     vim.notify.setup {
	--       on_open = function(win)
	--         vim.api.nvim_win_set_config(win, { focusable = false })
	--       end,
	--       stages = 'static',
	--       timeout = 3000,
	--     }
	--     vim.keymap.set('n', '<Esc>', function()
	--       require('notify').dismiss { silent = true }
	--     end, { desc = 'dismiss notify popup and clear hlsearch' })
	--   end,
	-- },
	-- {
	--   'noice.nvim',
	--   event = 'DeferredUIEnter',
	--   load = function(_)
	--     vim.cmd.packadd 'nui.nvim'
	--     -- vim.cmd.packadd 'nvim-notify'
	--   end,
	--   after = function(_)
	--     require('noice').setup {}
	--   end,
	-- },
	{
		"staline.nvim",
		load = function(_)
			vim.cmd.packadd("nvim-web-devicons")
			vim.cmd.packadd("staline.nvim")
		end,
		after = function(_)
			require("staline").setup({
				sections = {
					left = {
						"▊",
						" ",
						{ "Evil", "mode" },
						" ",
						"file_name",
						" ",
						"branch",
					},
					mid = { "lsp" },
					right = {
						"lsp_name",
						" ",
						"file_size",
						" ",
						"line_column",
					},
				},
				mode_colors = {
					n = "#38b1f0",
					i = "#9ece6a",
					c = "#e27d60",
					v = "#c678dd",
					V = "#c678dd",
				},
				defaults = {
					true_colors = true,
					line_column = " [%l/%L] :%c ",
					branch_symbol = " ",
					mod_symbol = "  ",
				},
				special_table = {
					NvimTree = { "File Explorer", " " },
					packer = { "Packer", " " },
					TelescopePrompt = { "Telescope", " " },
					mason = { "Mason", " " },
					lze = { "lze", " " },
				},
				lsp_symbols = {
					Error = " ",
					Info = " ",
					Warn = " ",
					Hint = " ",
				},
			})
		end,
	},
	{
		"gitsigns.nvim",
		event = "DeferredUIEnter",
		after = function(_)
			require("gitsigns").setup({
				signs = {
					add = { text = "│" },
					change = { text = "│" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				numhl = false,
				linehl = false,
				word_diff = false,
				watch_gitdir = {
					interval = 1000,
					follow_files = true,
				},
				attach_to_untracked = true,
				current_line_blame = false,
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol",
					delay = 1000,
					ignore_whitespace = false,
				},
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
				sign_priority = 6,
				update_debounce = 100,
				status_formatter = nil,
				max_file_length = 40000,
				preview_config = {
					border = "rounded",
					style = "minimal",
					relative = "cursor",
					row = 0,
					col = 1,
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Next hunk" })

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Previous hunk" })

					map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk" })
					map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
					map("v", "<leader>gs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Stage selected hunk" })
					map("v", "<leader>gr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Reset selected hunk" })
					map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage buffer" })
					map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
					map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset buffer" })
					map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
					map("n", "<leader>gb", function()
						gs.blame_line({ full = true })
					end, { desc = "Blame line" })
					map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
					map("n", "<leader>gd", gs.toggle_word_diff, { desc = "Diff this inline buffer" })
					map("n", "<leader>gD", gs.diffthis, { desc = "Diff this buffer side by side" })
					map("n", "<leader>gtd", gs.toggle_deleted, { desc = "Toggle deleted" })

					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
				end,
			})
		end,
	},
	--
	{
		"which-key.nvim",
		event = "DeferredUIEnter",
		after = function(_)
			require("which-key").setup({
				plugins = {
					marks = true,
					registers = true,
					spelling = {
						enabled = true,
						suggestions = 20,
					},
					presets = {
						operators = true,
						motions = true,
						text_objects = true,
						windows = true,
						nav = true,
						z = true,
						g = true,
					},
				},
				icons = {
					breadcrumb = "»",
					separator = "➜",
					group = "+",
				},
				show_help = true,
				disable = {
					buftypes = {},
					filetypes = { "TelescopePrompt" },
				},
			})

			require("which-key").add({
				{ "<leader><leader>", group = "buffer commands" },
				{ "<leader><leader>_", hidden = true },
				{ "<leader>c", group = "[c]ode" },
				{ "<leader>c_", hidden = true },
				{ "<leader>d", group = "[d]ocument" },
				{ "<leader>d_", hidden = true },
				{ "<leader>g", group = "[g]it" },
				{ "<leader>g_", hidden = true },
				{ "<leader>h", group = "[h]arpoon" },
				{ "<leader>h_", hidden = true },
				{ "<leader>l", group = "[l]sp" },
				{ "<leader>l_", hidden = true },
				{ "<leader>t", group = "[t]oggles" },
				{ "<leader>t_", hidden = true },
			})
		end,
	},
	{
		"lazygit.nvim",
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<CR>", mode = { "n" }, desc = "LazyGit (root dir)" },
			{
				"<leader>gG",
				function()
					vim.cmd("Telescope lazygit")
				end,
				mode = { "n" },
				desc = "LazyGit repositories",
			},
		},
		-- load = function(_)
		--   vim.cmd.packadd 'plenary.nvim'
		--   vim.cmd.packadd 'telescope.nvim'
		--   vim.cmd.packadd 'kd-lazygit'
		-- end,
		before = function(_)
			vim.fn.sign_define("LazyGitAugend", { text = "+", texthl = "GreenSign" })
			vim.fn.sign_define("LazyGitReword", { text = "~", texthl = "YellowSign" })
			vim.fn.sign_define("LazyGitDelete", { text = "-", texthl = "RedSign" })
		end,
		after = function(_)
			require("telescope").load_extension("lazygit")
		end,
	},
	{
		"harpoon",
		load = function(name)
			vim.cmd.packadd("plenary.nvim")
			vim.cmd.packadd("telescope.nvim")
			vim.cmd.packadd(name)
		end,
		after = function(_)
			local harpoon = require("harpoon")
			harpoon:setup({})
			require("telescope").load_extension("harpoon")

			vim.keymap.set("n", "<leader>hs", function()
				harpoon:list():add()
			end, { desc = "Harpoon add file" })

			vim.keymap.set("n", "<leader>hd", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon quick menu" })

			vim.keymap.set("n", "&", function()
				harpoon:list():select(1)
			end, { desc = "Harpoon file 1" })

			vim.keymap.set("n", "é", function()
				harpoon:list():select(2)
			end, { desc = "Harpoon file 2" })

			vim.keymap.set("n", '"', function()
				harpoon:list():select(3)
			end, { desc = "Harpoon file 3" })

			vim.keymap.set("n", "'", function()
				harpoon:list():select(4)
			end, { desc = "Harpoon file 4" })

			vim.keymap.set("n", "(", function()
				harpoon:list():select(5)
			end, { desc = "Harpoon file 5" })

			vim.keymap.set("n", "§", function()
				harpoon:list():select(6)
			end, { desc = "Harpoon file 6" })

			vim.keymap.set("n", "è", function()
				harpoon:list():select(7)
			end, { desc = "Harpoon file 7" })

			vim.keymap.set("n", "!", function()
				harpoon:list():select(8)
			end, { desc = "Harpoon file 8" })

			vim.keymap.set("n", "ç", function()
				harpoon:list():select(9)
			end, { desc = "Harpoon file 9" })

			vim.keymap.set("n", "<leader>hp", function()
				harpoon:list():prev()
			end, { desc = "Harpoon prev file" })

			vim.keymap.set("n", "<leader>hn", function()
				harpoon:list():next()
			end, { desc = "Harpoon next file" })
		end,
	},
	{
		"vim-tmux-navigator",
		event = "DeferredUIEnter",
	},
	{
		"vimtex",
		ft = "tex",
		lazy = false,
		after = function(_)
			local os_name = vim.loop.os_uname().sysname
			if os_name == "Linux" then
				vim.g.vimtex_view_general_viewer = "zathura"
			else
				vim.g.vimtex_view_method = "skim"
				vim.g.vimtex_view_skim_sync = 1
				vim.g.vimtex_view_skim_activate = 1
			end
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_quickfix_mode = 2
			vim.g.vimtex_syntax_enabled = false

			vim.keymap.set("n", "<leader>tC", "<cmd>VimtexCompile<cr>", { desc = "Compile Tex" })
			vim.keymap.set("n", "<leader>tS", "<cmd>VimtexStopAll<cr>", { desc = "Stop all Tex compilations" })
		end,
	},
	{
		"opencode.nvim",
		keys = {
			{
				"<leader>ct",
				function()
					require("opencode").toggle()
				end,
				desc = "Toggle opencode",
			},
			{
				"<leader>ca",
				function()
					require("opencode").ask()
				end,
				desc = "Ask opencode",
				mode = { "n", "v" },
			},
			{
				"<leader>cA",
				function()
					require("opencode").ask("@file ")
				end,
				desc = "Ask opencode about current file",
				mode = { "n", "v" },
			},
			{
				"<leader>cs",
				function()
					require("opencode").ask("@this ")
				end,
				desc = "Ask opencode about current selection",
				mode = "v",
			},
			{
				"<leader>cn",
				function()
					require("opencode").command("/new")
				end,
				desc = "New session",
			},
			{
				"<leader>ce",
				function()
					require("opencode").prompt("Explain @this and its context")
				end,
				desc = "Explain code near cursor",
			},
			{
				"<leader>cr",
				function()
					require("opencode").prompt("Review @file for correctness and readability")
				end,
				desc = "Review file",
			},
			{
				"<leader>cf",
				function()
					require("opencode").prompt("Fix these @diagnostics")
				end,
				desc = "Fix errors",
			},
			{
				"<leader>co",
				function()
					require("opencode").prompt("Optimize @this for performance and readability")
				end,
				desc = "Optimize selection",
				mode = "v",
			},
			{
				"<leader>cd",
				function()
					require("opencode").prompt("Add documentation comments for @this")
				end,
				desc = "Document selection",
				mode = "v",
			},
			{
				"<leader>ct",
				function()
					require("opencode").prompt("Add tests for @this")
				end,
				desc = "Test selection",
				mode = "v",
			},
			{
				"<leader>W",
				function()
					require("opencode").prompt([[
                 I want you act as a proofreader and experienced academic writer.
                 I will provide you texts and I would like you to review them, and rephrase them
                 to provide a better version according to the folowing standards:

                 - Correct any spelling, grammar, or punctuation errors.
                 - Do not use any contractions like I'm or you're.
                 - Just replace the orignal text with the revised text without anything else.

                 Also beware to make your response follow these requirements:

                 *   **Feel:** No language or vocabulary that would make the output feel like AI generated.
                 *   **Sentence Length:** A mix of short and medium-length sentences.
                 *   **Vocabulary:** As precise as possible.
                 *   **Voice:** Use the active voice.
                 *   **Content:** The idea should be clear and concise.
                 *   **Flow:** The ideas should flow logically.
                 *   **Latex:** Dot not change the custom LaTeX commands that may be used.

                 The text is here: @this
               ]])
				end,
				desc = "Better academic writing",
				mode = "v",
			},
			{
				"<leader>C",
				function()
					require("opencode").prompt([[
                 I want you act as a proofreader and experienced academic writer.
                 I will provide you texts and I would like you to review them, and rephrase them
                 as little as possible to provide a better version according to the folowing standards:

                 - Correct any spelling, grammar, or punctuation errors.
                 - Do not use any contractions like I'm or you're.
                 - Just replace the orignal text with the revised text without anything else.

                 Also beware to make your response follow these requirements:

                 *   **Feel:** No language or vocabulary that would make the output feel like AI generated.
                 *   **Sentence Length:** A mix of short and medium-length sentences.
                 *   **Vocabulary:** As precise as possible.
                 *   **Voice:** Use the active voice.
                 *   **Content:** The idea should be clear and concise.
                 *   **Flow:** The ideas should flow logically.
                 *   **Latex:** Dot not change the custom LaTeX commands that may be used.

                 Most importantly: you must change the orginal text the least possible.

                 The text is here: @this
               ]])
				end,
				desc = "Better academic correction",
				mode = "v",
			},
		},
		after = function()
			vim.g.opencode_opts = {
				auto_register_cmp_sources = { "opencode", "buffer" },
				auto_reload = false,
				auto_focus = false,
				command = "opencode",
				win = {
					position = "right",
				},
			}
		end,
	},

	{
		"supermaven-nvim",
		event = "DeferredUIEnter",
		after = function(_)
			require("supermaven-nvim").setup({
				disable_inline_completion = false,
				disable_keymaps = false,
			})
		end,
	},

	{
		"Comment.nvim",
		event = "DeferredUIEnter",
		load = function(_)
			vim.cmd.packadd("nvim-ts-context-commentstring")
			vim.cmd.packadd("Comment.nvim")
		end,
		after = function(_)
			require("ts_context_commentstring").setup({
				enable_autocmd = false,
			})

			-- Hook it directly into Comment.nvim
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
	},

	{
		"nvim-surround",
		event = "DeferredUIEnter",
		after = function(_)
			require("nvim-surround").setup()
		end,
	},

	{
		"indent-blankline.nvim",
		event = "DeferredUIEnter",
		after = function(_)
			require("ibl").setup()
		end,
	},

	{
		"vim-sleuth",
		event = "DeferredUIEnter",
	},

	{
		"trouble.nvim",
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
			{
				"<leader>xl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
		},
		event = "DeferredUIEnter",
		after = function(_)
			require("trouble").setup({})
		end,
	},

	{
		"nvim-colorizer.lua",
		event = { "BufReadPost", "BufNewFile" },
		after = function(_)
			require("colorizer").setup({
				user_default_options = {
					names = false,
					RGB = true,
					RRGGBB = true,
					RRGGBBAA = true,
					AARRGGBB = true,
					rgb_fn = true,
					hsl_fn = true,
					css = true,
					css_fn = true,
					mode = "background",
					tailwind = true,
					sass = { enable = false },
				},
			})
		end,
	},

	{
		"treesj",
		cmd = { "TSJToggle" },
		keys = { { "<leader>Tt", ":TSJToggle<CR>", mode = { "n" }, desc = "treesj split/join" } },
		after = function(_)
			require("treesj").setup({})
		end,
	},
}
