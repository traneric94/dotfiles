local which_key = require("which-key")

which_key.setup({})

-- Leader group labels. Registered HERE (after lazy loads which-key) rather than
-- in keymaps.lua, which runs during init before the plugin exists.
local groups = {
  b = "buffers",
  d = "debug",
  e = "explorer",
  f = "find",
  g = "git",
  h = "harpoon",
  l = "lsp",
  q = "quickfix",
  s = "search",
  t = "test",
  v = "neovim",
}

if which_key.add then
  local spec = {}
  for key, name in pairs(groups) do
    table.insert(spec, { "<leader>" .. key, group = name })
  end
  which_key.add(spec)
else
  local reg = {}
  for key, name in pairs(groups) do
    reg[key] = { name = "+" .. name }
  end
  which_key.register({ ["<leader>"] = reg })
end
