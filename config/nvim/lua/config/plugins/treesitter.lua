local treesitter = require("nvim-treesitter.configs")
treesitter.setup({
  ensure_installed = {
    "bash",
    "css",
    "dockerfile",
    "go",
    "hcl",
    "html",
    "javascript",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "proto",
    "python",
    "ruby",
    "rust",
    "terraform",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "yaml",
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["as"] = "@scope",
      },
    },
  },
})
