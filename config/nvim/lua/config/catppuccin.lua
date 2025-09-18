-- Catppuccin configuration
local status_ok, catppuccin = pcall(require, "catppuccin")
if not status_ok then
  return
end

catppuccin.setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
  background = { -- :h background
      light = "latte",
      dark = "mocha",
  },
  transparent_background = false,
  show_end_of_buffer = false,
  term_colors = true,
  dim_inactive = {
      enabled = false,
      shade = "dark",
      percentage = 0.15,
  },
  integrations = {
      coc_nvim = true,
      telescope = true,
      harpoon = true,
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
      treesitter = true,
      semantic_tokens = true,
  },
  custom_highlights = function(colors)
    return {
      -- LSP and CoC highlighting
      CocErrorSign = { fg = colors.red },
      CocWarningSign = { fg = colors.yellow },
      CocInfoSign = { fg = colors.sky },
      CocHintSign = { fg = colors.teal },
      CocErrorHighlight = { bg = colors.none, sp = colors.red, undercurl = true },
      CocWarningHighlight = { bg = colors.none, sp = colors.yellow, undercurl = true },
      CocInfoHighlight = { bg = colors.none, sp = colors.sky, undercurl = true },
      CocHintHighlight = { bg = colors.none, sp = colors.teal, undercurl = true },
      -- Enhanced semantic highlighting
      CocSemClass = { fg = colors.yellow, style = { "bold" } },
      CocSemEnum = { fg = colors.peach },
      CocSemInterface = { fg = colors.yellow, style = { "italic" } },
      CocSemStruct = { fg = colors.yellow, style = { "bold" } },
      CocSemType = { fg = colors.yellow },
      CocSemTypeParameter = { fg = colors.maroon, style = { "italic" } },
      CocSemVariable = { fg = colors.text },
      CocSemParameter = { fg = colors.maroon, style = { "italic" } },
      CocSemEnumMember = { fg = colors.teal },
      CocSemFunction = { fg = colors.blue, style = { "bold" } },
      CocSemMethod = { fg = colors.blue, style = { "bold" } },
      CocSemProperty = { fg = colors.teal },
      CocSemKeyword = { fg = colors.mauve, style = { "bold" } },
      CocSemModifier = { fg = colors.mauve },
      CocSemNamespace = { fg = colors.pink, style = { "italic" } },
      CocSemOperator = { fg = colors.sky },
      CocSemComment = { fg = colors.overlay1, style = { "italic" } },
      CocSemString = { fg = colors.green },
      CocSemNumber = { fg = colors.peach },
      CocSemRegexp = { fg = colors.pink },
      CocSemDecorator = { fg = colors.pink },
      -- Treesitter enhancements
      ["@function"] = { fg = colors.blue, style = { "bold" } },
      ["@function.builtin"] = { fg = colors.sky, style = { "bold" } },
      ["@method"] = { fg = colors.blue, style = { "bold" } },
      ["@parameter"] = { fg = colors.maroon, style = { "italic" } },
      ["@variable"] = { fg = colors.text },
      ["@variable.builtin"] = { fg = colors.red, style = { "italic" } },
      ["@field"] = { fg = colors.teal },
      ["@property"] = { fg = colors.teal },
      -- Enhanced type differentiation
      ["@type"] = { fg = colors.yellow },
      ["@type.builtin"] = { fg = colors.peach, style = { "bold" } }, -- string, int, bool
      ["@type.definition"] = { fg = colors.yellow, style = { "bold" } }, -- struct definitions
      ["@type.qualifier"] = { fg = colors.mauve }, -- const, var keywords
      ["@constructor"] = { fg = colors.sapphire },
      ["@constant"] = { fg = colors.peach, style = { "bold" } },
      ["@constant.builtin"] = { fg = colors.flamingo, style = { "bold" } }, -- true, false, nil
      ["@number"] = { fg = colors.peach },
      ["@number.float"] = { fg = colors.peach, style = { "italic" } },
      ["@boolean"] = { fg = colors.flamingo, style = { "bold" } },
      ["@string"] = { fg = colors.green },
      ["@string.escape"] = { fg = colors.pink },
      ["@character"] = { fg = colors.teal },
      ["@comment"] = { fg = colors.overlay1, style = { "italic" } },
      ["@keyword"] = { fg = colors.mauve, style = { "bold" } },
      ["@keyword.function"] = { fg = colors.mauve, style = { "bold" } },
      ["@keyword.operator"] = { fg = colors.mauve },
      ["@keyword.return"] = { fg = colors.pink, style = { "bold" } },
      ["@keyword.import"] = { fg = colors.pink },
      ["@operator"] = { fg = colors.sky },
      ["@punctuation"] = { fg = colors.overlay2 },
      ["@punctuation.delimiter"] = { fg = colors.overlay2 },
      ["@punctuation.bracket"] = { fg = colors.overlay2 },
      ["@punctuation.special"] = { fg = colors.sky },
      -- Go-specific enhancements
      ["@namespace"] = { fg = colors.pink, style = { "italic" } },
      ["@label"] = { fg = colors.sapphire, style = { "italic" } },
      ["@tag"] = { fg = colors.mauve },
      ["@tag.attribute"] = { fg = colors.teal },
      ["@tag.delimiter"] = { fg = colors.overlay2 },
    }
  end,
})

-- Set Catppuccin colorscheme
pcall(vim.cmd.colorscheme, "catppuccin")