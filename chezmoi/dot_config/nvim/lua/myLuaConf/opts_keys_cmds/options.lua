-- Neovim options configuration

local opt = vim.opt
local g = vim.g
local o = vim.o

-- Leader key
g.mapleader = ' '
g.maplocalleader = ' '

-- Clipboard settings
-- Share clipboard between vim and system
opt.clipboard = 'unnamedplus'

-- Line numbers
opt.number = true
opt.relativenumber = false
opt.ttimeoutlen = 1

-- Tab settings
opt.tabstop = 4
opt.softtabstop = 4
opt.showtabline = 0
opt.expandtab = true

-- Indentation
opt.smartindent = true
opt.shiftwidth = 2
opt.breakindent = true

-- Search settings
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.grepprg = 'rg --vimgrep'
opt.grepformat = '%f:%l:%c:%m'

-- Text wrapping
opt.wrap = false
-- opt.textwidth = 80
opt.wrapmargin = 0
opt.formatoptions = 't'
opt.linebreak = false

-- Split behavior
opt.splitbelow = true
opt.splitright = true

-- Enable mouse
opt.mouse = 'a'

-- Decrease updatetime
opt.updatetime = 50

-- Better completion experience
opt.completeopt = { 'menuone', 'noselect', 'noinsert' }

-- Undo and backup settings
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- Enable 24-bit colors
opt.termguicolors = true

-- UI elements
opt.signcolumn = 'yes'
opt.cursorline = true

-- Fold settings
opt.foldcolumn = '0'
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Scrolling
opt.scrolloff = 8

-- Timeout for key sequences
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0

-- Encoding
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'

-- Spell checking
opt.spell = false
opt.spelllang = 'en_us'

-- Cursor options
opt.guicursor = {
  'n-v-c:block',
  'i-ci-ve:ver100',
  'r-cr:hor20',
  'o:hor50',
  'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',
  'sm:block-blinkwait175-blinkoff150-blinkon175',
}

-- Show invisible characters
opt.list = true
opt.listchars = 'eol:↲,space: ,tab:   ,trail:•,extends:→,precedes:←,nbsp:␣'

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Command line height
opt.cmdheight = 0

-- Hide mode display (INSERT, VISUAL, etc.)
opt.showmode = false

-- Popup menu height
opt.pumheight = 0

-- Format expression
opt.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Global statusline
opt.laststatus = 3

-- Neovide specific settings
if g.neovide then
  -- Neovide options
  g.neovide_cursor_animation_length = 0.02
  g.neovide_fullscreen = false
  g.neovide_hide_mouse_when_typing = false
  g.neovide_refresh_rate = 144
  g.neovide_cursor_vfx_mode = 'ripple'
  g.neovide_cursor_animate_command_line = true
  g.neovide_cursor_animate_in_insert_mode = true
  g.neovide_cursor_vfx_particle_lifetime = 5.0
  g.neovide_cursor_vfx_particle_density = 14.0
  g.neovide_cursor_vfx_particle_speed = 12.0
  g.neovide_transparency = 0.8
  g.neovide_theme = 'auto'

  -- Neovide Fonts
  o.guifont = 'Comic Code Ligatures:h13'
  -- o.guifont = "CommitMono:Medium:h15"
  -- o.guifont = "JetBrainsMono Nerd Font:h14:Medium:i"
  -- o.guifont = "FiraMono Nerd Font:Medium:h14"
  -- o.guifont = "CaskaydiaCove Nerd Font:h14:b:i"
  -- o.guifont = "BlexMono Nerd Font Mono:h14:Medium:i"
  -- o.guifont = "Liga SFMono Nerd Font:b:h15"
end

g.snacks_animate = false
