local bufferline = require("bufferline")
bufferline.setup({
  options = {
    diagnostics = "nvim_lsp",
    show_buffer_close_icons = false,
    show_close_icon = false,
    separator_style = "slant",
    enforce_regular_tabs = false,
    offsets = {
      {
        filetype = "NvimTree",
        text = "Explorer",
        text_align = "left",
        separator = true,
      },
    },
  },
})
