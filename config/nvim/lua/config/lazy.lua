local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local NVIM_DAP_URL = "https://codeberg.org/mfussenegger/nvim-dap"
if not vim.uv.fs_stat(lazypath) then
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
  { "https://codeberg.org/mfussenegger/nvim-lint" },
  { "kunchenguid/comment-repl.nvim" },

  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" } },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", dependencies = { "williamboman/mason.nvim" } },
  { "neovim/nvim-lspconfig" },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  { NVIM_DAP_URL },
  { "jay-babu/mason-nvim-dap.nvim", dependencies = { "williamboman/mason.nvim", NVIM_DAP_URL } },
  { "rcarriga/nvim-dap-ui", dependencies = { NVIM_DAP_URL, "nvim-neotest/nvim-nio" } },
  { "theHamsta/nvim-dap-virtual-text", dependencies = { NVIM_DAP_URL } },

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

-- Load each plugin config in isolation: a failure in one shouldn't abort the
-- rest (previously an error here left every later plugin unconfigured).
for _, mod in ipairs({
  "config.plugins.catppuccin",
  "config.plugins.nvim-tree",
  "config.plugins.lualine",
  "config.plugins.bufferline",
  "config.plugins.gitsigns",
  "config.plugins.treesitter",
  "config.plugins.telescope",
  "config.plugins.mason-tool-installer",
  "config.plugins.conform",
  "config.plugins.lint",
  "config.plugins.dap",
  "config.plugins.lsp",
  "config.plugins.copilot",
  "config.plugins.autopairs",
  "config.plugins.comment",
  "config.plugins.comment-repl",
  "config.plugins.which-key",
}) do
  local ok, err = pcall(require, mod)
  if not ok then
    vim.schedule(function()
      vim.notify(string.format("plugin config '%s' failed: %s", mod, err), vim.log.levels.ERROR)
    end)
  end
end
