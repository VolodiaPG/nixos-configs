-- Treesitter configuration
return {
  {
    'nvim-treesitter',
    event = { 'BufReadPre', 'BufNewFile' },
    dep_of = { 'treesj', 'otter.nvim', 'codecompanion.nvim', 'render-markdown', 'neorg' },
    load = function(name)
      require('lzextras').loaders.multi {
        name,
        'nvim-treesitter-context',
        'nvim-treesitter-textobjects',
      }
    end,
    after = function(_)
      -- vim.defer_fn(function()
      require('nvim-treesitter').setup {
        highlight = {
          enable = true,
        },
        indent = { enable = false },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<M-t>',
            node_incremental = '<M-t>',
            scope_incremental = '<M-T>',
            node_decremental = '<M-r>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = '@class.outer',
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          },
        },
      }
      -- end, 0)
      --
      -- Enable treesitter for all buffers
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local language = vim.treesitter.language.get_lang(args.match)
          if language and vim.treesitter.language.add(language) then
            vim.treesitter.start(args.buf, language)
          end
        end,
      })
    end,
  },
}
