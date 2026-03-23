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

-- Resolve the current buffer's project root by walking up for known markers.
-- Falls back to the global cwd when none are found (e.g. /tmp scratch files).
local PROJECT_MARKERS = {
  ".git",
  "go.mod",
  "package.json",
  "Gemfile",
  "pyproject.toml",
  "Cargo.toml",
}

local function project_root()
  return vim.fs.root(0, PROJECT_MARKERS) or vim.fn.getcwd()
end

local function telescope(builtin, opts)
  return function()
    local ok, builtin_module = pcall(require, "telescope.builtin")
    if not ok or not builtin_module[builtin] then
      return
    end
    builtin_module[builtin](opts or {})
  end
end

-- Like telescope() but resolves cwd to the project root at call time so each
-- invocation scopes to whichever repo the current buffer lives in.
local function telescope_project(builtin, extra_opts)
  return function()
    local ok, builtin_module = pcall(require, "telescope.builtin")
    if not ok or not builtin_module[builtin] then
      return
    end
    local opts = vim.tbl_extend("force", extra_opts or {}, { cwd = project_root() })
    builtin_module[builtin](opts)
  end
end

local function telescope_frecency()
  local ok, t = pcall(require, "telescope")
  if not ok or not t.extensions.frecency then
    return
  end
  t.extensions.frecency.frecency({ cwd = project_root() })
end

-- Lazy DAP action: resolves at call time so `dap` plugin failure doesn't
-- error on nvim startup, only on the keypress.
local function dap_action(fn)
  return function()
    local ok, dap = pcall(require, "dap")
    if not ok then
      return
    end
    fn(dap)
  end
end

local function with_nvim_tree(callback)
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    callback(api)
  end
end

-- Leader setup ----------------------------------------------------------------
map({ "n", "v" }, "<Space>", "<Nop>", "Leader key placeholder")
map("v", "<BS>", "x", "Delete selection")

-- Mode transitions -------------------------------------------------------------
map("i", "kj", "<Esc>", "Escape insert")

-- Core actions -----------------------------------------------------------------
map("n", "<leader>w", "<cmd>w<CR>", "Save file")
map("n", "<leader>W", "<cmd>wa<CR>", "Save all files")
map("n", "<leader>q", "<cmd>confirm q<CR>", "Quit window")
map("n", "<leader>Q", "<cmd>confirm qa<CR>", "Quit Neovim")
map("n", "<leader>sc", "<cmd>nohlsearch<CR>", "Clear search highlight")

map("n", "<leader>tt", "<cmd>terminal<CR>", "Terminal buffer")

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
-- Project-scoped pickers resolve to the buffer's nearest project root so they
-- always search the right repo, regardless of nvim's global cwd.
map("n", "<leader>ff", telescope_project("find_files"), "Find files (project root)")
map("n", "<leader>fF", telescope("find_files"), "Find files (cwd, escape hatch)")
map("n", "<leader>fg", telescope_project("live_grep"), "Live grep (project root)")
map("n", "<leader>fr", telescope_frecency, "Frecency (opened files, project root)")
map("n", "<leader>fb", telescope("buffers"), "Find buffers")
map("n", "<leader>fh", telescope("help_tags"), "Help tags")
map("n", "<leader>fo", telescope("oldfiles"), "Recent files (oldfiles)")
map("n", "<leader>fs", telescope("git_status"), "Git status")
map("n", "<leader>fc", telescope("git_commits"), "Git commits")
map("n", "<leader>fw", telescope_project("grep_string"), "Search word under cursor (project root)")
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

-- Toggle ----------------------------------------------------------------------
map("n", "<leader>tc", function()
  vim.g.cmp_enabled = not vim.g.cmp_enabled
  vim.notify(string.format("Completion %s", vim.g.cmp_enabled and "enabled" or "disabled"))
end, "Toggle completion")

-- Debug (DAP) ------------------------------------------------------------------
map("n", "<leader>db", dap_action(function(dap) dap.toggle_breakpoint() end), "Debug: toggle breakpoint")
map("n", "<leader>dc", dap_action(function(dap) dap.continue() end), "Debug: continue")
map("n", "<leader>di", dap_action(function(dap) dap.step_into() end), "Debug: step into")
map("n", "<leader>do", dap_action(function(dap) dap.step_over() end), "Debug: step over")
map("n", "<leader>dO", dap_action(function(dap) dap.step_out() end), "Debug: step out")
map("n", "<leader>dr", dap_action(function(dap) dap.repl.open() end), "Debug: open REPL")
map("n", "<leader>dl", dap_action(function(dap) dap.run_last() end), "Debug: run last")
map("n", "<leader>dk", dap_action(function(dap)
  if dap.session() then
    dap.terminate()
  end
end), "Debug: terminate")
map("n", "<leader>du", function()
  local ok, dapui = pcall(require, "dapui")
  if ok then
    dapui.toggle({})
  end
end, "Debug: toggle UI")

-- Testing ----------------------------------------------------------------------
map("n", "<leader>tn", "<cmd>TestNearest<CR>", "Test nearest")
map("n", "<leader>tt", utils.toggle_test_file, "Toggle test file")
map("n", "<leader>ts", "<cmd>TestSuite<CR>", "Test suite")
map("n", "<leader>tl", "<cmd>TestLast<CR>", "Test last")
map("n", "<leader>tv", "<cmd>TestVisit<CR>", "Test visit")
map("n", "<leader>tf", "<cmd>TestFile<CR>", "Test file")

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
  end
end, "Add file to Harpoon")
map("n", "<leader>hh", function()
  local ok, ui = pcall(require, "harpoon.ui")
  if ok then
    ui.toggle_quick_menu()
  end
end, "Harpoon menu")
for i = 1, 4 do
  map("n", string.format("<leader>h%d", i), function()
    local ok, ui = pcall(require, "harpoon.ui")
    if ok then
      ui.nav_file(i)
    end
  end, string.format("Harpoon file %d", i))
end

-- Diagnostic navigation --------------------------------------------------------
map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
map("n", "<leader>lq", vim.diagnostic.setqflist, "Diagnostics to quickfix")

if wk_ok then
  wk.register({
    ["<leader>"] = {
      b = { name = "+buffers" },
      d = { name = "+debug" },
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
