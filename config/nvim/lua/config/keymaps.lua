local utils = require("config.utils")

local function map(mode, lhs, rhs, desc, opts)
  if type(desc) == "table" and opts == nil then
    opts = desc
    desc = opts.desc
  end
  opts = opts or {}
  if opts.silent == nil then
    opts.silent = true
  end
  if desc then
    opts.desc = desc
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

local wk_ok, wk = pcall(require, "which-key")

local function telescope(builtin, opts)
  return function()
    local ok, builtin_module = pcall(require, "telescope.builtin")
    if not ok then
      local lazy_ok, lazy = pcall(require, "lazy")
      if lazy_ok then
        lazy.load({ plugins = { "telescope.nvim" } })
        ok, builtin_module = pcall(require, "telescope.builtin")
      end
    end
    if ok and builtin_module[builtin] then
      builtin_module[builtin](opts or {})
    else
      vim.notify("Telescope is not available", vim.log.levels.ERROR)
    end
  end
end

local function with_nvim_tree(callback)
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    callback(api)
  else
    vim.notify("nvim-tree is not available", vim.log.levels.ERROR)
  end
end

-- Leader setup ----------------------------------------------------------------
map({ "n", "v" }, "<Space>", "<Nop>", "Leader key placeholder")
map("v", "<BS>", "x", "Delete selection")

-- Mode transitions -------------------------------------------------------------
map("i", "jk", "<Esc>", "Escape insert")
map("i", "kj", "<Esc>", "Escape insert")

-- Core actions -----------------------------------------------------------------
map("n", "<leader>w", "<cmd>w<CR>", "Save file")
map("n", "<leader>W", "<cmd>wa<CR>", "Save all files")
map("n", "<leader>q", "<cmd>confirm q<CR>", "Quit window")
map("n", "<leader>Q", "<cmd>confirm qa<CR>", "Quit Neovim")
map("n", "<leader>sc", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- Clipboard --------------------------------------------------------------------
map({ "n", "v" }, "<leader>y", '"+y', "Yank to system clipboard")
map({ "n", "v" }, "<leader>p", '"+p', "Paste from system clipboard")

-- File explorer ----------------------------------------------------------------
map("n", "<leader>e", function()
  with_nvim_tree(function(api)
    api.tree.toggle({ focus = true, find_file = true })
  end)
end, "Toggle file explorer")
map("n", "<leader>er", function()
  with_nvim_tree(function(api)
    api.tree.reload()
  end)
end, "Reload file explorer")
map("n", "<leader>ef", function()
  with_nvim_tree(function(api)
    api.tree.find_file({ open = true, focus = true })
  end)
end, "Reveal file in explorer")

-- Telescope / search -----------------------------------------------------------
map("n", "<leader>ff", telescope("find_files"), "Find files")
map("n", "<leader>fg", telescope("live_grep"), "Live grep")
map("n", "<leader>fb", telescope("buffers"), "Find buffers")
map("n", "<leader>fh", telescope("help_tags"), "Help tags")
map("n", "<leader>fr", telescope("oldfiles"), "Recent files")
map("n", "<leader>fs", telescope("git_status"), "Git status")
map("n", "<leader>fc", telescope("git_commits"), "Git commits")
map("n", "<leader>fw", telescope("grep_string"), "Search word under cursor")
map("n", "<leader>fd", telescope("diagnostics"), "Diagnostics picker")
map("n", "<leader>/", telescope("current_buffer_fuzzy_find"), "Search in buffer")
map("n", "<leader>sr", telescope("resume"), "Resume last picker")

-- Buffers ----------------------------------------------------------------------
map("n", "<leader>bb", "<cmd>b#<CR>", "Alternate buffer")
map("n", "<leader>bn", "<cmd>bnext<CR>", "Next buffer")
map("n", "<leader>bp", "<cmd>bprevious<CR>", "Previous buffer")
map("n", "<leader>bd", "<cmd>bp | bd #<CR>", "Delete buffer")
map("n", "<leader>bl", "<cmd>ls<CR>", "List buffers", { silent = false })
map("n", "<leader>bx", "<cmd>%bd|e#|bd#<CR>", "Delete all but current")
map("n", "<leader>b[", "<cmd>BufferLineCyclePrev<CR>", "Cycle buffer left")
map("n", "<leader>b]", "<cmd>BufferLineCycleNext<CR>", "Cycle buffer right")

for i = 1, 9 do
  map("n", string.format("<leader>%d", i), string.format("<cmd>BufferLineGoToBuffer %d<CR>", i), string.format("Go to buffer %d", i))
end
map("n", "<leader>0", "<cmd>BufferLineGoToBuffer -1<CR>", "Go to last buffer")

-- Git --------------------------------------------------------------------------
map("n", "<leader>gs", "<cmd>Git<CR>", "Git status")
map("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", "Diff current file")
map("n", "<leader>gc", "<cmd>Git commit<CR>", "Commit", { silent = false })
map("n", "<leader>gb", "<cmd>GBrowse<CR>", "Open in browser", { silent = false })
map("v", "<leader>gb", "<cmd>GBrowse<CR>", "Open selection in browser", { silent = false })
map("n", "<leader>gl", function()
  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.toggle_current_line_blame()
  else
    vim.notify("gitsigns is not available", vim.log.levels.ERROR)
  end
end, "Toggle line blame")
map("n", "<leader>gp", utils.open_pull_request, "Open PR for line")

-- Quickfix ---------------------------------------------------------------------
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix")
map("n", "<leader>qq", utils.clear_quickfix, "Clear quickfix")
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprev<CR>", "Previous quickfix item")
map("n", "<leader>ql", "<cmd>lopen<CR>", "Open location list")
map("n", "<leader>qL", "<cmd>lclose<CR>", "Close location list")

-- Testing ----------------------------------------------------------------------
map("n", "<leader>tn", "<cmd>TestNearest<CR>", "Test nearest")
map("n", "<leader>tf", "<cmd>TestFile<CR>", "Test file")
map("n", "<leader>ts", "<cmd>TestSuite<CR>", "Test suite")
map("n", "<leader>tl", "<cmd>TestLast<CR>", "Test last")
map("n", "<leader>tv", "<cmd>TestVisit<CR>", "Test visit")
map("n", "<leader>ta", utils.toggle_test_file, "Toggle test file")

-- Neovim config ----------------------------------------------------------------
map("n", "<leader>ve", function()
  vim.cmd("edit ~/.config/nvim/init.lua")
end, "Edit Neovim config")
map("n", "<leader>r", function()
  vim.cmd("source ~/.config/nvim/init.lua")
  vim.notify("Config reloaded!", vim.log.levels.INFO)
end, "Reload Neovim config")

-- Harpoon ----------------------------------------------------------------------
map("n", "<leader>ha", function()
  local ok, harpoon = pcall(require, "harpoon.mark")
  if ok then
    harpoon.add_file()
  else
    vim.notify("harpoon is not available", vim.log.levels.ERROR)
  end
end, "Add file to Harpoon")
map("n", "<leader>hh", function()
  local ok, ui = pcall(require, "harpoon.ui")
  if ok then
    ui.toggle_quick_menu()
  else
    vim.notify("harpoon is not available", vim.log.levels.ERROR)
  end
end, "Harpoon menu")
for i = 1, 4 do
  map("n", string.format("<leader>h%d", i), function()
    local ok, ui = pcall(require, "harpoon.ui")
    if ok then
      ui.nav_file(i)
    else
      vim.notify("harpoon is not available", vim.log.levels.ERROR)
    end
  end, string.format("Harpoon file %d", i))
end

-- Diagnostic navigation --------------------------------------------------------
map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
map("n", "<leader>lq", vim.diagnostic.setloclist, "Diagnostics to location list")

if wk_ok then
  wk.register({
    ["<leader>"] = {
      b = { name = "+buffers" },
      e = { name = "+explorer" },
      f = { name = "+find" },
      g = { name = "+git" },
      h = { name = "+harpoon" },
      l = { name = "+lsp" },
      r = "Reload config",
      q = { name = "+quickfix" },
      s = { name = "+search" },
      t = { name = "+test" },
      v = { name = "+neovim" },
    },
  })
end
