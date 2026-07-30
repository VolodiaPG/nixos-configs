-- Neovim keymaps configuration

local map = vim.keymap.set

-- Disable arrow keys
map({ 'n', 'i' }, '<Up>', '<Nop>', { silent = true, noremap = true, desc = 'Disable Up arrow key' })
map({ 'n', 'i' }, '<Down>', '<Nop>', { silent = true, noremap = true, desc = 'Disable Down arrow key' })
map({ 'n', 'i' }, '<Right>', '<Nop>', { silent = true, noremap = true, desc = 'Disable Right arrow key' })
map({ 'n', 'i' }, '<Left>', '<Nop>', { silent = true, noremap = true, desc = 'Disable Left arrow key' })

-- Disable autocompletion keys
map({ 'i' }, '<Tab>', '<Nop>', { silent = true, noremap = true, desc = 'Disable Tab by default' })
map({ 'i' }, '<C-y>', '<Nop>', { silent = true, noremap = true, desc = 'Disable C-y by default' })

-- Better window navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Navigate to the left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Navigate to the bottom window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Navigate to the top window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Navigate to the right window' })

-- Resize windows
map('n', '<C-Up>', ':resize -2<CR>', { silent = true, desc = 'Decrease window height' })
map('n', '<C-Down>', ':resize +2<CR>', { silent = true, desc = 'Increase window height' })
map('n', '<C-Left>', ':vertical resize -2<CR>', { silent = true, desc = 'Decrease window width' })
map('n', '<C-Right>', ':vertical resize +2<CR>', { silent = true, desc = 'Increase window width' })

-- Stay in indent mode when indenting
map('v', '<', '<gv', { desc = 'Decrease indent and stay in visual mode' })
map('v', '>', '>gv', { desc = 'Increase indent and stay in visual mode' })

-- Move text up and down
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selected text down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selected text up' })

-- Keep cursor centered when scrolling
map('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center' })
map('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center' })

-- Keep cursor centered when searching
map('n', 'n', 'nzzzv', { desc = 'Next search result and center' })
map('n', 'N', 'Nzzzv', { desc = 'Previous search result and center' })

-- Keep original text in register when pasting over selection
map('x', 'p', [["_dP]], { desc = 'Paste without yanking selection' })

-- Delete without yanking
map({ 'n', 'v' }, '<leader>d', [["_d]], { desc = 'Delete without yanking' })

-- Clear search highlights
-- map('n', '<leader>h', ':nohlsearch<CR>', { desc = 'Clear search highlights' })

-- Save file
map('n', '<C-s>', ':w<CR>', { desc = 'Save file' })

-- Better buffer navigation
map('n', '<S-l>', ':bnext<CR>', { desc = 'Next buffer' })
map('n', '<S-h>', ':bprevious<CR>', { desc = 'Previous buffer' })
-- map('n', '<leader>c', ':bd<CR>', { desc = 'Close buffer' })

-- Format document
-- map('n', '<leader>f', function()
--   vim.lsp.buf.format { async = true }
-- end, { desc = 'Format document' })

-- Diagnostic navigation
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic error messages' })
map('n', '<leader>l', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

