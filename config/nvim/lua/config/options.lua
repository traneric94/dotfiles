local opt = vim.opt
local g = vim.g

opt.ruler = true
opt.formatoptions = opt.formatoptions + "o"
opt.formatoptions = opt.formatoptions - "t"
opt.wrap = false
opt.modeline = true
opt.linespace = 0
opt.joinspaces = false
opt.splitbelow = true
opt.splitright = true
opt.scrolloff = 3
opt.sidescrolloff = 5
opt.startofline = false
opt.errorbells = false
opt.backspace = { "indent", "eol", "start" }
opt.showcmd = true
opt.showmode = true
opt.swapfile = true
opt.backup = false
opt.encoding = "utf-8"
opt.autowriteall = true
opt.autoread = true
opt.laststatus = 2
opt.fileformats = { "unix", "dos", "mac" }
opt.showmatch = true
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.autoindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.gdefault = true
opt.magic = true
opt.number = true
opt.relativenumber = true
-- Defer clipboard until after startup (skips a provider probe on launch);
-- unnamedplus so yanks hit the system clipboard (not X11 PRIMARY) on Linux too.
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)
opt.colorcolumn = "100"
opt.mouse = "a"
opt.list = true
opt.listchars = {
  tab = "  ",
  trail = "·",
  extends = "»",
  precedes = "«",
  nbsp = "⣿",
}
opt.previewheight = 12
opt.completeopt = { "menu", "menuone", "noselect" }
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = { "%f:%l:%c:%m" }
opt.foldenable = false
opt.undofile = true -- persistent undo across sessions (undodir auto-created under stdpath('state'))
opt.signcolumn = "yes" -- always show sign column so text doesn't jump when signs/diagnostics appear
opt.updatetime = 250 -- faster CursorHold: LSP document-highlight + gitsigns feel live
opt.confirm = true -- prompt to save instead of erroring on :q with unsaved changes

g.python3_host_prog = vim.fn.exepath("python3")
g.go_bin_path = vim.fn.expand("$HOME/go/bin/")
g.ruby_indent_assignment_style = "variable"
g.ruby_indent_block_style = "do"
g.ruby_space_errors = 1
g.ruby_operators = 1
g.typescript_indent_disable = 0
