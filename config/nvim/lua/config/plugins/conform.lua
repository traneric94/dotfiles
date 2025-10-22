local conform = require("conform")
local tools = require("config.tools")

conform.setup({
  formatters_by_ft = tools.formatters_by_ft(),
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return false
    end
    return { timeout_ms = 1000, lsp_fallback = true }
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
