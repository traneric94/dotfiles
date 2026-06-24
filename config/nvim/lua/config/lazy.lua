local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "akinsho/bufferline.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "lewis6991/gitsigns.nvim" },

  { "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate" },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "master",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      "nvim-telescope/telescope-frecency.nvim",
      "ThePrimeagen/harpoon",
    },
  },

  { "vim-test/vim-test" },
  { "tpope/vim-fugitive", dependencies = { "tpope/vim-rhubarb" } },
  { "mg979/vim-visual-multi", branch = "master" },
  { "numToStr/Comment.nvim" },
  { "folke/which-key.nvim" },
  { "windwp/nvim-autopairs" },
  { "stevearc/conform.nvim" },
  { "mfussenegger/nvim-lint" },
  { "kunchenguid/comment-repl.nvim" },

  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" } },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", dependencies = { "williamboman/mason.nvim" } },
  { "neovim/nvim-lspconfig" },
  { "folke/neodev.nvim" },

  { "mfussenegger/nvim-dap" },
  { "jay-babu/mason-nvim-dap.nvim", dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" } },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  { "theHamsta/nvim-dap-virtual-text", dependencies = { "mfussenegger/nvim-dap" } },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      { "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
    },
  },

  { "zbirenbaum/copilot.lua" },
  { "zbirenbaum/copilot-cmp", dependencies = { "zbirenbaum/copilot.lua" } },
}, {
  defaults = { lazy = false },
  install = { colorscheme = { "catppuccin" } },
  rocks = { enabled = false },
  change_detection = { notify = false },
})

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
require("config.plugins.comment-repl")
require("config.plugins.which-key")
