local api = vim.api
local utils = require("config.utils")

-- Number toggle (relative when focused)
local numbertoggle = api.nvim_create_augroup("NumberToggle", { clear = true })
api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = true
    end
  end,
})

api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
  end,
})

-- Auto-open nvim-tree
local nvim_tree_group = api.nvim_create_augroup("NvimTreeAutoOpen", { clear = true })
api.nvim_create_autocmd("VimEnter", {
  group = nvim_tree_group,
  callback = function(data)
    local directory = vim.fn.isdirectory(data.file) == 1
    local no_name = data.file == "" and vim.fn.argc() == 0
    local ok, tree = pcall(require, "nvim-tree.api")
    if not ok then
      return
    end

    if directory then
      vim.cmd.cd(data.file)
      tree.tree.open()
      return
    end

    if no_name then
      tree.tree.open()
    end
  end,
})

-- Config reload message
local config_group = api.nvim_create_augroup("ConfigReload", { clear = true })
api.nvim_create_autocmd("BufWritePost", {
  group = config_group,
  pattern = vim.fn.expand("~/.config/nvim/init.lua"),
  callback = function()
    vim.cmd("source ~/.config/nvim/init.lua")
    vim.notify("Config auto-reloaded!")
  end,
})

-- Go format on save
local go_format_group = api.nvim_create_augroup("GoFormat", { clear = true })
api.nvim_create_autocmd("BufWritePost", {
  group = go_format_group,
  pattern = "*.go",
  callback = utils.go_format,
})

-- Fold imports after read/write
local fold_group = api.nvim_create_augroup("AutoFoldImports", { clear = true })
api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = fold_group,
  pattern = { "*.go", "*.ts", "*.tsx", "*.js", "*.jsx", "*.rb", "*.py" },
  callback = utils.fold_imports,
})

-- Go makeprg / errorformat
local gomake = api.nvim_create_augroup("GoMake", { clear = true })
api.nvim_create_autocmd("FileType", {
  group = gomake,
  pattern = "go",
  callback = function()
    vim.bo.makeprg = "make"
    vim.bo.errorformat = "%E%f:%l:%c: %m,%E%f:%l: %m,%-G%.%#"
  end,
})
