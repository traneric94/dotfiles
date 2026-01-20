local data_path = vim.fn.stdpath("data")
local plug_path = data_path .. "/site/autoload/plug.vim"
local plug_bootstrap = false

if not vim.loop.fs_stat(plug_path) then
  plug_bootstrap = true
  vim.fn.system({
    "curl",
    "-fLo",
    plug_path,
    "--create-dirs",
    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
  })
end

local function plug(cmd)
  vim.cmd(cmd)
end

vim.fn["plug#begin"](data_path .. "/plugged")

plug("Plug 'catppuccin/nvim', { 'as': 'catppuccin' }")
plug("Plug 'nvim-lua/plenary.nvim'")
plug("Plug 'nvim-tree/nvim-web-devicons'")
plug("Plug 'nvim-tree/nvim-tree.lua'")
plug("Plug 'nvim-lualine/lualine.nvim'")
plug("Plug 'akinsho/bufferline.nvim'")
plug("Plug 'lewis6991/gitsigns.nvim'")
plug("Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }")
plug("Plug 'nvim-treesitter/nvim-treesitter-textobjects'")
plug("Plug 'nvim-telescope/telescope.nvim'")
if vim.fn.executable("make") == 1 then
  plug("Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }")
end
plug("Plug 'nvim-telescope/telescope-frecency.nvim'")
plug("Plug 'ThePrimeagen/harpoon'")
plug("Plug 'vim-test/vim-test'")
plug("Plug 'tpope/vim-fugitive'")
plug("Plug 'tpope/vim-rhubarb'")
plug("Plug 'mg979/vim-visual-multi', { 'branch': 'master' }")
plug("Plug 'numToStr/Comment.nvim'")
plug("Plug 'folke/which-key.nvim'")
plug("Plug 'WhoIsSethDaniel/mason-tool-installer.nvim'")
plug("Plug 'windwp/nvim-autopairs'")
plug("Plug 'stevearc/conform.nvim'")
plug("Plug 'mfussenegger/nvim-lint'")
plug("Plug 'mfussenegger/nvim-dap'")
plug("Plug 'jay-babu/mason-nvim-dap.nvim'")
plug("Plug 'rcarriga/nvim-dap-ui'")
plug("Plug 'nvim-neotest/nvim-nio'")
plug("Plug 'theHamsta/nvim-dap-virtual-text'")
plug("Plug 'neovim/nvim-lspconfig'")
plug("Plug 'williamboman/mason.nvim'")
plug("Plug 'williamboman/mason-lspconfig.nvim'")
plug("Plug 'hrsh7th/nvim-cmp'")
plug("Plug 'hrsh7th/cmp-buffer'")
plug("Plug 'hrsh7th/cmp-path'")
plug("Plug 'hrsh7th/cmp-nvim-lsp'")
plug("Plug 'hrsh7th/cmp-cmdline'")
plug("Plug 'saadparwaiz1/cmp_luasnip'")
plug("Plug 'L3MON4D3/LuaSnip'")
plug("Plug 'rafamadriz/friendly-snippets'")
plug("Plug 'folke/neodev.nvim'")
plug("Plug 'zbirenbaum/copilot.lua'")
plug("Plug 'zbirenbaum/copilot-cmp'")

vim.fn["plug#end"]()

vim.g["test#strategy"] = "neovim"

require("config.plugins.catppuccin")
require("config.plugins.nvim-tree")
require("config.plugins.lualine")
require("config.plugins.bufferline")
require("config.plugins.gitsigns")
require("config.plugins.treesitter")
require("config.plugins.telescope")
require("config.plugins.mason-tool-installer")
require("config.plugins.conform")
require("config.plugins.lint")
require("config.plugins.dap")
require("config.plugins.lsp")
require("config.plugins.copilot")
require("config.plugins.autopairs")
require("config.plugins.comment")
require("config.plugins.which-key")

if plug_bootstrap then
  vim.schedule(function()
    vim.notify("vim-plug installed. Run :PlugInstall to fetch plugins.", vim.log.levels.INFO)
  end)
end
