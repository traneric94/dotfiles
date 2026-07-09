local kanagawa = require("kanagawa")

-- Lotus: Kanagawa's LIGHT variant (daytime). wave/dragon are the dark ones.
-- Force a light background so lualine 'auto' and plugins render light-correct.
vim.o.background = "light"
kanagawa.setup({
  theme = "lotus",
  background = { light = "lotus", dark = "wave" },
  transparent = false,
  terminalColors = true,
  dimInactive = false,
})

vim.cmd.colorscheme("kanagawa")
