vim.pack.add({
  'https://github.com/BirdeeHub/lze',
  'https://github.com/BirdeeHub/lzextras',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/mfussenegger/nvim-lint',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/norcalli/nvim-colorizer.lua',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/folke/noice.nvim',
  'https://github.com/folke/trouble.nvim',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/rcarriga/nvim-notify',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2', name = 'harpoon' },
  'https://github.com/tamton-aquib/staline.nvim',
  'https://github.com/MysticalDevil/inlay-hints.nvim',
  'https://github.com/kylechui/nvim-surround',
  'https://github.com/L3MON4D3/LuaSnip',
  'https://github.com/saghen/blink.lib',
  'https://github.com/saghen/blink.cmp',
  'https://github.com/lukas-reineke/indent-blankline.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/supermaven-inc/supermaven-nvim',
  'https://github.com/lervag/vimtex',
  'https://github.com/tpope/vim-sleuth',
  'https://github.com/kdheepak/lazygit.nvim',
  'https://github.com/christoomey/vim-tmux-navigator',
  'https://github.com/nickjvandyke/opencode.nvim',
  'https://github.com/numToStr/Comment.nvim',
  'https://github.com/Wansmer/treesj',
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/nvim-telescope/telescope-live-grep-args.nvim',
  'https://github.com/xzbdmw/colorful-menu.nvim',
}, {
  load = function() end,
  confirm = true,
})

require 'myLuaConf.init'

vim.cmd.packadd 'lze'
vim.cmd.packadd 'lzextras'
setmetatable(require 'lze', getmetatable(require 'lzextras'))

local lze = require 'lze'
lze.register_handlers(lze.lsp)
lze.register_handlers(require('lzextras').lsp)

lze.load {
  { import = 'myLuaConf.plugins.telescope' },
  { import = 'myLuaConf.plugins.treesitter' },
  { import = 'myLuaConf.plugins.completion' },
  { import = 'myLuaConf.plugins' },
  { import = 'myLuaConf.LSPs' },
  { import = 'myLuaConf.lint' },
  { import = 'myLuaConf.format' },
}

local socket_path = '/tmp/nvim_' .. vim.loop.os_getpid()
vim.fn.serverstart(socket_path)
