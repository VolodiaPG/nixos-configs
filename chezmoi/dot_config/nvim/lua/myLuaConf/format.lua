-- Conform (formatter)

return {
  {
    'conform.nvim',
    for_cat = 'general.always',
    event = { 'BufWritePre' },
    after = function(_)
      require('conform').setup {
        formatters_by_ft = {
          lua = { 'stylua' },
          python = { 'ruff' }, --[[ 'isort' ]]
          javascript = { 'prettierd' },
          typescript = { 'prettierd' },
          javascriptreact = { 'prettierd' },
          typescriptreact = { 'prettierd' },
          json = { 'prettierd' },
          html = { 'prettierd' },
          css = { 'prettierd' },
          scss = { 'prettierd' },
          markdown = { 'prettierd' },
          yaml = { 'prettierd' },
          shell = { 'shfmt', 'shellcheck', 'shellharden' },
          rust = { 'rustfmt' },
          go = { 'gofmt' },
          -- tex = { 'latexindent', 'typos' },
          tex = { 'latexindent' },
          nix = { 'nixfmt' },
          r = { 'air' },
          elixir = { 'mix', 'credo' },
          typst = { 'typstyle' },
          ['*'] = { 'trim_whitespace' },
        },
        format_after_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 3000, lsp_fallback = true }
        end,
        formatters = {
          shfmt = {
            prepend_args = { '-i', '2', '-ci' },
          },
          stylua = {
            prepend_args = { '--indent-type', 'Spaces', '--indent-width', '2' },
          },
        },
      }

      vim.api.nvim_create_user_command('FormatDisable', function(args)
        if args.bang then
          vim.g.disable_autoformat = true
        else
          vim.b.disable_autoformat = true
        end
      end, { desc = 'Disable autoformatting', bang = true })

      vim.api.nvim_create_user_command('FormatEnable', function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = 'Enable autoformatting' })
    end,
  },
}
