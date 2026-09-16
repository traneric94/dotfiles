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

local function fzf(fn, opts)
  return function()
    local ok, fzf_lua = pcall(require, "fzf-lua")
    if not ok then return end
    fzf_lua[fn](opts or {})
  end
end

local function fzf_project(fn, extra_opts)
  return function()
    local ok, fzf_lua = pcall(require, "fzf-lua")
    if not ok then return end
    local opts = vim.tbl_extend("force", extra_opts or {}, { cwd = project_root() })
    fzf_lua[fn](opts)
  end
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

-- Option toggles (vim-unimpaired yo* style; the one unimpaired family nvim 0.11 didn't adopt)
for key, o in pairs({ yow = "wrap", yos = "spell", yol = "list", yon = "number", yor = "relativenumber", yoc = "cursorline" }) do
  map("n", key, function()
    vim.opt_local[o] = not vim.opt_local[o]:get()
  end, "Toggle " .. o)
end
map("n", "yoh", "<cmd>set hlsearch!<CR>", "Toggle hlsearch")

map("n", "<leader>T", "<cmd>terminal<CR>", "Terminal buffer")

-- Clipboard --------------------------------------------------------------------
map({ "n", "v" }, "<leader>y", '"+y', "Yank to system clipboard")
map({ "n", "v" }, "<leader>p", '"+p', "Paste from system clipboard")
-- Paste over a visual selection without clobbering the yank/clipboard register
-- (black-hole the deleted text, then paste-before). Lets you paste the same
-- snippet over multiple selections in a row.
map("x", "p", [["_dP]], "Paste over selection, keep register")

-- Splits ----------------------------------------------------------------------
map("n", "<leader>sv", "<cmd>vsplit<CR>", "Split vertical")
map("n", "<leader>sh", "<cmd>split<CR>", "Split horizontal")
map("n", "<leader>se", "<C-w>=", "Equalize splits")
map("n", "<leader>sx", "<cmd>close<CR>", "Close split")
map("n", "<leader>sz", "<C-w>|<C-w>_", "Zoom split (maximize)")

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

-- fzf-lua / search ------------------------------------------------------------
-- Project-scoped pickers resolve to the buffer's nearest project root so they
-- always search the right repo, regardless of nvim's global cwd.
map("n", "<leader>ff", fzf_project("files"), "Find files (project root)")
map("n", "<leader>fF", fzf("files"), "Find files (cwd, escape hatch)")
map("n", "<leader>fg", fzf_project("live_grep"), "Live grep (project root)")
map("n", "<leader>fr", fzf_project("oldfiles", { cwd_only = true }), "Recent files (project root)")
map("n", "<leader>fb", fzf("buffers"), "Find buffers")
map("n", "<leader>fh", fzf("help_tags"), "Help tags")
map("n", "<leader>fo", fzf("oldfiles"), "Recent files (global)")
map("n", "<leader>fs", fzf("git_status"), "Git status")
map("n", "<leader>fc", fzf("git_commits"), "Git commits")
map("n", "<leader>fw", fzf_project("grep_cword"), "Search word under cursor (project root)")
map("n", "<leader>fd", fzf("diagnostics_document"), "Diagnostics picker")
map("n", "<leader>ls", fzf("lsp_document_symbols"), "Document symbols")
map("n", "<leader>lS", fzf("lsp_live_workspace_symbols"), "Workspace symbols")
map("n", "<leader>/", fzf("blines"), "Search in buffer")
map("n", "<leader>sr", fzf("resume"), "Resume last picker")

-- Buffers ----------------------------------------------------------------------
map("n", "<leader>bb", "<cmd>b#<CR>", "Alternate buffer")
map("n", "<leader>bd", "<cmd>bp | bd #<CR>", "Delete buffer")
map("n", "<leader>bl", "<cmd>ls<CR>", "List buffers", { silent = false })
map("n", "<leader>bx", "<cmd>%bd|e#|bd#<CR>", "Delete all but current")
map("n", "<leader>b[", "<cmd>BufferLineCyclePrev<CR>", "Cycle buffer left")
map("n", "<leader>b]", "<cmd>BufferLineCycleNext<CR>", "Cycle buffer right")

for i = 1, 9 do
  map("n", string.format("<leader>%d", i), string.format("<cmd>BufferLineGoToBuffer %d<CR>", i), string.format("Go to buffer %d", i))
end
map("n", "<leader>0", "<cmd>BufferLineGoToBuffer -1<CR>", "Go to last buffer")

-- Git hunks (gitsigns) --------------------------------------------------------
map("n", "<leader>hs", function() require("gitsigns").stage_hunk() end, "Stage hunk")
map("v", "<leader>hs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk (selection)")
map("n", "<leader>hu", function() require("gitsigns").undo_stage_hunk() end, "Unstage hunk")
map("n", "<leader>hr", function() require("gitsigns").reset_hunk() end, "Reset hunk")
map("v", "<leader>hr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk (selection)")
map("n", "<leader>hR", function() require("gitsigns").reset_buffer() end, "Reset buffer")
map("n", "<leader>hp", function() require("gitsigns").preview_hunk() end, "Preview hunk")

-- Git --------------------------------------------------------------------------
map("n", "<leader>gs", "<cmd>Git<CR>", "Git status")
map("n", "<leader>gD", "<cmd>Gdiffsplit<CR>", "Diff current file")
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
map("n", "]h", function() require("gitsigns").nav_hunk("next") end, "Next git hunk")
map("n", "[h", function() require("gitsigns").nav_hunk("prev") end, "Previous git hunk")

-- Quickfix ---------------------------------------------------------------------
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix")
map("n", "<leader>qq", utils.clear_quickfix, "Clear quickfix")
-- ]q/[q and count-aware ]Q/[Q are nvim 0.11 built-in defaults — don't shadow them.
map("n", "<leader>ql", "<cmd>lopen<CR>", "Open location list")
map("n", "<leader>qL", "<cmd>lclose<CR>", "Close location list")

-- Toggles ---------------------------------------------------------------------
map("n", "<leader>uf", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify(string.format("Autoformat %s", vim.g.disable_autoformat and "disabled" or "enabled"))
end, "Toggle autoformat")

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
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
map("n", "<leader>lq", vim.diagnostic.setqflist, "Diagnostics to quickfix")

-- which-key group labels are registered in config/plugins/which-key.lua (which
-- runs after lazy bootstraps which-key). Registering them here ran during
-- init, before the plugin existed, so the labels never took effect.
