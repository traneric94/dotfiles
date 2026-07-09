local kanagawa = require("kanagawa")

-- Wave: the dark variant measured easiest on the eyes (muted ukiyo-e palette,
-- low blue-light load, ~11:1 contrast on a soft dark ground).
kanagawa.setup({
  theme = "wave",
  background = { dark = "wave" },
  transparent = false,
  terminalColors = true,
  dimInactive = false,
})

vim.cmd.colorscheme("kanagawa")
