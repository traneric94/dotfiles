local comment = require("Comment")
local ts_context = pcall(require, "ts_context_commentstring")

comment.setup({
  pre_hook = ts_context and require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook() or nil,
})
