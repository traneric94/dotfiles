local utils = require("config.utils")

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  if opts.silent == nil then
    opts.silent = true
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Search and replace
map("n", "<leader>s", ":%s//g<Left><Left>", { silent = false, desc = "Global substitute" })

-- Basic movement and editing
map("n", "<Space>", "<PageDown>", { noremap = true })
map("v", "<BS>", "x", { noremap = true })

-- Insert mode escape shortcuts
map("i", "jk", "<Esc>", { noremap = true })
map("i", "kj", "<Esc>", { noremap = true })

-- Clipboard operations
map("n", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
map("v", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Go helpers
map("n", "<leader>mf", utils.go_format, { desc = "Go: format" })
map("n", "<leader>tn", ":TestNearest<CR>", { desc = "Test nearest" })
map("n", "<leader>tf", ":TestFile<CR>", { desc = "Test file" })
map("n", "<leader>ta", ":TestSuite<CR>", { desc = "Test suite" })
map("n", "<leader>tl", ":TestLast<CR>", { desc = "Test last" })
map("n", "<leader>tv", ":TestVisit<CR>", { desc = "Test visit" })

-- Tabs
map("n", "<leader>tn", ":tabnew<CR>", { desc = "Tab new" })
map("n", "<leader>tc", ":tabclose<CR>", { desc = "Tab close" })

-- Clear highlights
map("n", "<C-l>", function()
  vim.cmd("nohlsearch")
end, { desc = "Clear search highlight" })

-- Viewport scrolling
map("n", "J", "<C-e>", { noremap = true })
map("n", "K", "<C-y>", { noremap = true })
map("n", "H", "zh", { noremap = true })
map("n", "L", "zl", { noremap = true })
map("n", "<leader>j", "J", { desc = "Join lines" })

-- Nvim-tree mappings
local function with_nvim_tree(fn)
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    fn(api)
  end
end

map("n", "<C-n>", function()
  with_nvim_tree(function(api)
    api.tree.toggle({ find_file = true, focus = true })
  end)
end, { desc = "Toggle file explorer" })

map("n", "<leader>nr", function()
  with_nvim_tree(function(api)
    api.tree.reload()
  end)
end, { desc = "Reload file explorer" })

map("n", "<leader>nf", function()
  with_nvim_tree(function(api)
    api.tree.find_file({ open = true, focus = true })
  end)
end, { desc = "Reveal file in explorer" })

-- Git mappings
map("n", "<leader>gg", "<cmd>Git<CR>", { desc = "Git status" })
map("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", { desc = "Git diffsplit" })
map("n", "<leader>gc", "<cmd>Git commit<CR>", { silent = false, desc = "Git commit" })
map("n", "<leader>gb", "<cmd>GBrowse<CR>", { silent = false, desc = "Open in GitHub" })
map("v", "<leader>gb", "<cmd>GBrowse<CR>", { silent = false, desc = "Open selection in GitHub" })
map("n", "<leader>bb", function()
  require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle line blame" })
map("n", "<leader>gp", utils.open_pull_request, { desc = "Open PR for line" })

-- Bufferline tab navigation
for i = 1, 9 do
  map("n", string.format("<leader>%d", i), string.format("<cmd>BufferLineGoToBuffer %d<CR>", i), { desc = "Go to buffer " .. i })
end
map("n", "<leader>0", function()
  local ok, bufferline = pcall(require, "bufferline")
  if ok then
    bufferline.go_to_buffer(-1, true)
  end
end, { desc = "Go to last buffer" })
map("n", "<leader>-", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map("n", "<leader>+", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })

-- Buffer handling
map("n", "<leader>l", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<C-h>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bq", ":bp | bd #<CR>", { desc = "Delete buffer" })
map("n", "<leader>bl", ":ls<CR>", { silent = false, desc = "List buffers" })
map("n", "<leader>n", function()
  vim.cmd("edit ~/.config/nvim/init.lua")
end, { desc = "Edit config" })
map("n", "<leader>r", function()
  vim.cmd("source ~/.config/nvim/init.lua")
  vim.notify("Config reloaded!", vim.log.levels.INFO)
end, { desc = "Reload config" })

-- Telescope mappings
local function telescope_cmd(fn)
  return function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if ok then
      vim.cmd("wincmd p")
      fn(telescope)
    end
  end
end

map("n", "<leader>ff", telescope_cmd(function(telescope)
  telescope.find_files()
end), { desc = "Telescope files" })

map("n", "<leader>fg", telescope_cmd(function(telescope)
  telescope.live_grep()
end), { desc = "Telescope live grep" })

map("n", "<leader>fb", telescope_cmd(function(telescope)
  telescope.buffers()
end), { desc = "Telescope buffers" })

map("n", "<leader>fh", telescope_cmd(function(telescope)
  telescope.help_tags()
end), { desc = "Telescope help" })

map("n", "<leader>fr", telescope_cmd(function(telescope)
  telescope.oldfiles()
end), { desc = "Telescope recent files" })

map("n", "<leader>fc", telescope_cmd(function(telescope)
  telescope.git_commits()
end), { desc = "Telescope git commits" })

map("n", "<leader>fs", telescope_cmd(function(telescope)
  telescope.git_status()
end), { desc = "Telescope git status" })

map("n", "<leader>vf", function()
  vim.cmd("vsplit")
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then
    telescope.find_files()
  end
end, { desc = "Vsplit + files" })

map("n", "<leader>vg", function()
  vim.cmd("vsplit")
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then
    telescope.live_grep()
  end
end, { desc = "Vsplit + live grep" })

map("n", "<leader>vb", function()
  vim.cmd("vsplit")
  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then
    telescope.buffers()
  end
end, { desc = "Vsplit + buffers" })

-- Grep helpers
map("n", "<leader>g", ":grep ", { silent = false, desc = "Grep prompt" })
map("n", "<leader>G", function()
  vim.cmd("grep " .. vim.fn.expand("<cword>"))
end, { desc = "Grep word under cursor" })

-- Quickfix
map("n", "<leader>co", "<cmd>copen<CR>", { desc = "Quickfix open" })
map("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Quickfix close" })
map("n", "<leader>cx", utils.clear_quickfix, { desc = "Quickfix clear" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Quickfix next" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "Quickfix prev" })
map("n", "]Q", "<cmd>clast<CR>", { desc = "Quickfix last" })
map("n", "[Q", "<cmd>cfirst<CR>", { desc = "Quickfix first" })

-- Test toggling
map("n", "<leader>tt", utils.toggle_test_file, { desc = "Toggle test file" })

-- Harpoon
map("n", "<leader>ha", function()
  require("harpoon.mark").add_file()
end, { desc = "Harpoon add file" })
map("n", "<leader>hh", function()
  require("harpoon.ui").toggle_quick_menu()
end, { desc = "Harpoon menu" })
map("n", "<leader>h1", function()
  require("harpoon.ui").nav_file(1)
end, { desc = "Harpoon file 1" })
map("n", "<leader>h2", function()
  require("harpoon.ui").nav_file(2)
end, { desc = "Harpoon file 2" })
map("n", "<leader>h3", function()
  require("harpoon.ui").nav_file(3)
end, { desc = "Harpoon file 3" })
map("n", "<leader>h4", function()
  require("harpoon.ui").nav_file(4)
end, { desc = "Harpoon file 4" })
