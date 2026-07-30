-- Neovim autocommands configuration

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- General settings
local general = augroup('General', { clear = true })

-- Highlight on yank
autocmd('TextYankPost', {
  group = general,
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
  end,
  desc = 'Highlight on yank',
})

-- Resize splits if window got resized
autocmd({ 'VimResized' }, {
  group = general,
  callback = function()
    vim.cmd 'tabdo wincmd ='
  end,
  desc = 'Resize splits on window resize',
})

-- Go to last location when opening a buffer
autocmd('BufReadPost', {
  group = general,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = 'Go to last location when opening a buffer',
})

-- Close some filetypes with <q>
autocmd('FileType', {
  group = general,
  pattern = {
    'qf',
    'help',
    'man',
    'notify',
    'lspinfo',
    'spectre_panel',
    'startuptime',
    'tsplayground',
    'PlenaryTestPopup',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
  desc = 'Close some filetypes with <q>',
})

-- Auto create dir when saving a file
autocmd('BufWritePre', {
  group = general,
  callback = function(event)
    if event.match:match '^%w%w+://' then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
  desc = "Create directory if it doesn't exist when saving a file",
})

-- Filetype-specific settings
local filetype_settings = augroup('FiletypeSettings', { clear = true })

-- Set indentation for specific filetypes
autocmd('FileType', {
  group = filetype_settings,
  pattern = { 'lua', 'javascript', 'typescript', 'json', 'html', 'css' },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
  desc = 'Set indentation to 2 spaces for specific filetypes',
})

-- Autowrap for textual files
autocmd('FileType', {
  group = filetype_settings,
  pattern = { 'tex', 'plaintex', 'latex', 'text', 'markdown' },
  callback = function()
    -- Set line width to 80 characters
    vim.opt_local.textwidth = 80
    -- Enable auto-wrapping for running text ('r') and new lines on 'o'/'O' ('o'), c for comments ('c'), t to enable text wrapp on textwidth
    vim.opt_local.formatoptions = 'rot'
    vim.opt_local.linebreak = true
  end,
  desc = 'Autowrap for textual files',
})

-- Terminal settings
local terminal = augroup('Terminal', { clear = true })

-- Enter insert mode when opening a terminal
autocmd('TermOpen', {
  group = terminal,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd 'startinsert'
  end,
  desc = 'Enter insert mode when opening a terminal',
})

-- Close terminal buffer on process exit
autocmd('BufLeave', {
  group = terminal,
  pattern = 'term://*',
  callback = function()
    vim.cmd 'stopinsert'
  end,
  desc = 'Exit insert mode when leaving a terminal buffer',
})

