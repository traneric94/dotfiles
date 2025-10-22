local lint = require("lint")
local tools = require("config.tools")
local linters_by_ft = tools.linters_by_ft()

local lint_name_map = {
  ["golangci-lint"] = "golangcilint",
}

local missing_linters_notified = {}
local resolved_linters_by_ft = {}

for ft, linters in pairs(linters_by_ft) do
  local resolved = {}
  for _, name in ipairs(linters) do
    local mapped = lint_name_map[name] or name
    if lint.linters[mapped] then
      table.insert(resolved, mapped)
    elseif not missing_linters_notified[mapped] then
      missing_linters_notified[mapped] = true
      vim.schedule(function()
        vim.notify(string.format("nvim-lint: linter '%s' is not defined", mapped), vim.log.levels.WARN)
      end)
    end
  end
  if #resolved > 0 then
    resolved_linters_by_ft[ft] = resolved
  else
    resolved_linters_by_ft[ft] = {}
  end
end

lint.linters_by_ft = resolved_linters_by_ft

if lint.linters.golangcilint then
  lint.linters.golangcilint.ignore_exitcode = true
end

local function normalize_names(names)
  local mapped = {}
  for _, name in ipairs(names or {}) do
    table.insert(mapped, lint_name_map[name] or name)
  end
  return mapped
end

local function lint_current_file()
  local ft = vim.bo.filetype
  local linters = lint.linters_by_ft[ft]
  if not linters or vim.tbl_isempty(linters) then
    return
  end

  lint.try_lint(normalize_names(linters))
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
