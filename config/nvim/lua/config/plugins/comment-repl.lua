-- comment-repl.nvim: in-buffer cell REPL (no equivalent in this config; dap and
-- vim-test do session-debug / whole-file, not ad-hoc cell eval).
--
-- Output is injected as `"""` blocks below the cell. conform's format_on_save
-- (black/ruff) would reflow those blocks, so executing a cell flips conform's
-- own buffer-local escape hatch `vim.b.disable_autoformat` (see
-- plugins/conform.lua) — saving then leaves the REPL output intact. Re-enable
-- with `:FormatEnable` if needed.
--
-- Scope: scratch / untracked buffers. The plugin mutates the buffer, so on a
-- tracked file the injected output lands in `git diff`.
local ok, comment_repl = pcall(require, "comment_repl")
if not ok then
  return
end

comment_repl.setup({})

local function execute_cell()
  vim.b.disable_autoformat = true
  vim.cmd("CommentREPLExecute")
end

vim.keymap.set("n", "<leader>ce", execute_cell, { desc = "Comment-REPL: execute cell" })
vim.keymap.set("n", "<leader>cl", "<cmd>CommentREPLLog<CR>", { desc = "Comment-REPL: view log" })
