-- LSP configuration

local function find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  if current_file == '' then
    current_dir = cwd
  else
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

return {
  {
    'nvim-lspconfig',
    on_require = { 'lspconfig' },
    keys = {
      { 'gd', vim.lsp.buf.definition, 'Goto Definition' },
      {
        'gr',
        function()
          require('telescope.builtin').lsp_references()
        end,
        'Goto References',
      },
      { 'gI', vim.lsp.buf.implementation, 'Goto Implementation' },
      { 'gD', vim.lsp.buf.declaration, 'Goto Declaration' },
      { 'K', vim.lsp.buf.hover, 'Hover Documentation' },
      { '<C-k>', vim.lsp.buf.signature_help, 'Signature Help' },
      { '<leader>rn', vim.lsp.buf.rename, 'Rename' },
      { '<leader>c,', vim.lsp.buf.code_action, 'Code Action' },
      { '<leader>D', vim.lsp.buf.type_definition, 'Type Definition' },
      {
        '<leader>ds',
        function()
          require('telescope.builtin').lsp_document_symbols()
        end,
        'Document Symbols',
      },
      {
        '<leader>dws',
        function()
          require('telescope.builtin').lsp_dynamic_workspace_symbols()
        end,
        'Workspace Symbols',
      },
    },
    lsp = function(plugin)
      local cmd = plugin.lsp.cmd or { plugin.name }
      plugin.lsp.cmd = cmd
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    before = function(_)
      vim.lsp.config('*', {
        on_attach = require 'myLuaConf.LSPs.on_attach',
      })
    end,
  },
  {
    'inlay-hints.nvim',
    after = function(_)
      require('inlay-hints').setup {
        only_current_line = false,
        eol = { right_align = false },
      }
    end,
  },
  -- {
  --   'lazydev.nvim',
  --   cmd = { 'LazyDev' },
  --   ft = 'lua',
  --   after = function(_)
  --     require('lazydev').setup {}
  --   end,
  -- },
  {
    'lua-language-server',
    lsp = {
      filetypes = { 'lua' },
      -- cmd = { 'lua-language-server' },
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          -- formatters = {
          --   ignoreComments = true,
          -- },
          -- signatureHelp = { enabled = true },
          -- diagnostics = {
          --   disable = { 'missing-fields' },
          -- },
          -- telemetry = { enabled = false },
        },
      },
    },
  },
  {
    'gopls',
    lsp = {
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    },
  },
  {
    'nixd',
    lsp = {
      filetypes = { 'nix' },
      settings = {
        nixd = {
          nixpkgs = {
            expr = [[import <nixpkgs> {}]],
          },
          formatting = {
            command = { 'nixfmt' },
          },
          diagnostic = {
            suppress = {
              'sema-escaping-with',
            },
          },
        },
      },
    },
  },
  --{ 'r_language_server', lsp = {
  --  filetypes = { 'r', 'rmd' },
  --} },
  {
    'expert',
    lsp = {
      filetypes = { 'elixir', 'eelixir', 'heex', 'surface' },
      cmd = { 'expert', '--stdio' },
      settings = {
        expert = {
          workspaceSymbols = {
            minQueryLength = 0,
          },
          rootMarkers = { 'mix.exs', '.git' },
        },
      },
    },
  },
  { 'bashls', lsp = {
    filetypes = { 'sh', 'bash' },
  } },
  { 'ty', lsp = {
    filetypes = { 'python' },
  } },
  {
    'ltex_plus',
    lsp = {
      filetypes = { 'tex' },
      settings = {
        ltex = {
          checkFrequency = 'save',
          enabled = { 'latex', 'tex' },
          language = 'auto',
          additionalRules = {
            enablePickyRules = true,
            motherTongue = { 'fr' },
          },
          dictionary = {
            ['en'] = { ':' .. find_git_root() .. '/dict.en.txt' },
            ['fr'] = { ':' .. find_git_root() .. '/dict.fr.txt' },
            ['auto'] = { ':' .. find_git_root() .. '/dict.auto.txt' },
          },
        },
      },
    },
  },
  {
    'texlab',
    lsp = {
      filetypes = { 'tex' },
      settings = {
        texlab = {
          build = {
            executable = 'latexmk',
            onSave = true,
            forwardSearchAfter = false,
          },
          forwardSearch = {
            executable = 'displayline',
            args = { '%l', '%p', '%f' },
          },
          chktex = {
            onEdit = false,
            onOpenAndSave = true,
          },
          inlayHints = {
            labelDefinitions = false,
            labelReferences = false,
          },
          diagnosticsDelay = 300,
          latexFormatter = 'latexindent',
        },
      },
    },
  },
  {
    'tinymist',
    lsp = {
      filetypes = { 'typst' },
      settings = {
        tinymist = {
          formatterMode = 'typstyle',
          exportPdf = 'onType',
          formatterProseWrap = true,
          formatterPrintWidth = 80,
          formatterIndentSize = 4,
        },
      },
    },
  },
}
