local copilot = require("copilot")
copilot.setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})

require("copilot_cmp").setup()
