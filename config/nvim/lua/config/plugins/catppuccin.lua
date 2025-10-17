local status_ok, catppuccin = pcall(require, "catppuccin")
if not status_ok then
  return
end

catppuccin.setup({
  flavour = "mocha",
  transparent_background = false,
  term_colors = true,
  integrations = {
    cmp = true,
    gitsigns = true,
    harpoon = true,
    mason = true,
    nvimtree = true,
    treesitter = true,
    telescope = true,
    which_key = true,
    native_lsp = {
      enabled = true,
      underlines = {
        errors = { "undercurl" },
        hints = { "undercurl" },
        warnings = { "undercurl" },
        information = { "undercurl" },
      },
      inlay_hints = {
        background = true,
      },
    },
  },
})

vim.cmd.colorscheme("catppuccin")
