-- Completion configuration using blink.cmp
return {
	{
		"luasnip",
		on_plugin = { "blink.cmp" },
		after = function(_)
			local luasnip = require("luasnip").config.setup({})
			require("luasnip.loaders.from_vscode").lazy_load()

			vim.keymap.set({ "i", "s" }, "<M-n>", function()
				if luasnip.choice_active() then
					luasnip.change_choice(1)
				end
			end)
		end,
	},
	{
		"colorful-menu.nvim",
		on_plugin = { "blink.cmp" },
	},
	{
		"blink.lib",
		on_plugin = { "blink.cmp" },
	},
	{
		"blink.cmp",
		-- event = "DeferredUIEnter",
		keys = {
			{
				"<C-y>",
				"accept",
				mode = "i",
			},
		},
		event = { "InsertEnter", "CmdlineEnter" },
		after = function(_)
			-- require('blink.cmp').build():wait(60000)
			require("blink.cmp").setup({
				keymap = {
					preset = "default",
				},
				cmdline = {
					enabled = true,
					completion = {
						menu = {
							auto_show = true,
						},
					},
					-- sources = function()
					--   local type = vim.fn.getcmdtype()
					--   if type == '/' or type == '?' then
					--     return { 'buffer' }
					--   end
					--   if type == ':' or type == '@' then
					--     return { 'cmdline', 'cmp_cmdline' }
					--   end
					--   return {}
					-- end,
				},
				fuzzy = {
					sorts = {
						"exact",
						"score",
						"sort_text",
					},
				},
				signature = {
					enabled = true,
					window = {
						show_documentation = true,
					},
				},
				completion = {
					menu = {
						draw = {
							treesitter = { "lsp" },
							components = {
								label = {
									text = function(ctx)
										return require("colorful-menu").blink_components_text(ctx)
									end,
									highlight = function(ctx)
										return require("colorful-menu").blink_components_highlight(ctx)
									end,
								},
							},
						},
					},
					documentation = {
						auto_show = true,
					},
				},
				snippets = {
					preset = "luasnip",
					-- active = function(filter)
					--   local snippet = require("luasnip")
					--   local blink = require("blink.cmp")
					--   if snippet.in_snippet() and not blink.is_visible() then
					--     return true
					--   else
					--     if not snippet.in_snippet() and vim.fn.mode() == "n" then
					--       snippet.unlink_current()
					--     end
					--     return false
					--   end
					-- end,
				},
				sources = {
					default = { "lsp", "path", "snippets", "buffer", "omni" },
					providers = {
						path = {
							score_offset = 50,
						},
						lsp = {
							score_offset = 40,
						},
						snippets = {
							score_offset = 40,
						},
						cmp_cmdline = {
							name = "cmp_cmdline",
							module = "blink.compat.source",
							score_offset = -100,
							opts = {
								cmp_name = "cmdline",
							},
						},
						supermaven = {
							name = "Supermaven",
							module = "blink.cmp.sources.luasnip",
							transform_items = function(_, items)
								local supermaven = require("supermaven-nvim.completion")
								local supermaven_completions = supermaven.get_completions()
								if supermaven_completions and #supermaven_completions > 0 then
									for _, completion in ipairs(supermaven_completions) do
										table.insert(items, {
											label = completion.text,
											kind = vim.lsp.protocol.CompletionItemKind.Text,
											insertText = completion.text,
										})
									end
								end
								return items
							end,
						},
					},
				},
			})
		end,
	},
}
