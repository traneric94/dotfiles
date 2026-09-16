local conform = require("conform")
local tools = require("config.tools")

-- Use `bundle exec rubocop` when the buffer's project has a Gemfile that
-- references rubocop. Falls back to the shim otherwise (e.g. standalone scripts).
local function rubocop_uses_bundle(ctx)
  local gemfile = vim.fn.findfile("Gemfile", ctx.dirname .. ";")
  if gemfile == "" then return false end
  local contents = vim.fn.readfile(gemfile)
  for _, line in ipairs(contents) do
    if line:match("rubocop") then return true end
  end
  return false
end

conform.formatters.rubocop = {
  command = function(self, ctx)
    return rubocop_uses_bundle(ctx) and "bundle" or "rubocop"
  end,
  args = function(self, ctx)
    local base = { "--server", "-a", "-f", "quiet", "--stderr", "--stdin", "$FILENAME" }
    if rubocop_uses_bundle(ctx) then
      return vim.list_extend({ "exec", "rubocop" }, base)
    end
    return base
  end,
  cwd = function(self, ctx)
    local gemfile = vim.fn.findfile("Gemfile", ctx.dirname .. ";")
    return gemfile ~= "" and vim.fn.fnamemodify(gemfile, ":h") or ctx.dirname
  end,
  stdin = true,
}

conform.setup({
  formatters_by_ft = tools.formatters_by_ft(),
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return false
    end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
  notify_on_error = true,
})

vim.api.nvim_create_user_command("FormatDisable", function(opts)
  if opts.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { bang = true, desc = "Disable autoformat-on-save" })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.g.disable_autoformat = false
  vim.b.disable_autoformat = false
end, { desc = "Enable autoformat-on-save" })
