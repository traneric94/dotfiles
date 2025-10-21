local ok, lint = pcall(require, "lint")
if not ok then
  return
end

local tools = require("config.tools")
local linters_by_ft = tools.linters_by_ft()

lint.linters_by_ft = linters_by_ft

local function lint_current_file()
  local ft = vim.bo.filetype
  local linters = lint.linters_by_ft[ft]
  if not linters or #linters == 0 then
    return
  end

  lint.try_lint(linters)
end

local augroup = vim.api.nvim_create_augroup("UserLinting", { clear = true })

vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufEnter" }, {
  group = augroup,
  callback = function()
    lint_current_file()
  end,
})

vim.api.nvim_create_user_command("LintNow", function()
  lint_current_file()
end, { desc = "Run configured linters for the current buffer" })
