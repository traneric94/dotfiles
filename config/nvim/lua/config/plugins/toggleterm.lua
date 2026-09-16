require("toggleterm").setup({
  size = function(term)
    if term.direction == "horizontal" then
      return 16
    elseif term.direction == "vertical" then
      return math.floor(vim.o.columns * 0.4)
    end
  end,
  open_mapping = [[<C-\>]],
  direction = "horizontal",
  shade_terminals = false,
  persist_mode = true,
  on_open = function(term)
    -- Exit terminal mode with Esc so normal keymaps still work
    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
  end,
})

-- Wire vim-test to run in the toggleterm window
vim.cmd([[
  function! ToggleTermStrategy(cmd) abort
    call luaeval("require('toggleterm').exec(_A[1])", [a:cmd])
  endfunction
  let g:test#custom_strategies = {'toggleterm': function('ToggleTermStrategy')}
]])
vim.g["test#strategy"] = "toggleterm"

-- Floating terminal for scratch/one-off commands
vim.keymap.set("n", "<leader>tf", function()
  local Terminal = require("toggleterm.terminal").Terminal
  Terminal:new({ direction = "float" }):toggle()
end, { desc = "Floating terminal", silent = true })
