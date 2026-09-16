local fzf = require("fzf-lua")

fzf.setup({
  winopts = {
    height = 0.85,
    width = 0.80,
    preview = {
      layout = "vertical",
      vertical = "down:45%",
    },
  },
  files = {
    cmd = "fd --type f --hidden --follow --exclude .git",
    git_icons = true,
  },
  grep = {
    cmd = "rg --color=always --smart-case --hidden --glob '!.git'",
  },
  keymap = {
    builtin = {
      ["<C-f>"] = "preview-page-up",
      ["<C-b>"] = "preview-page-down",
    },
    fzf = {
      ["ctrl-q"] = "select-all+accept",
    },
  },
  actions = {
    files = {
      ["default"] = fzf.actions.file_edit,
      ["ctrl-x"]  = fzf.actions.file_split,
      ["ctrl-v"]  = fzf.actions.file_vsplit,
      ["ctrl-t"]  = fzf.actions.file_tabedit,
      ["ctrl-q"]  = { fzf.actions.file_sel_to_qf, fzf.actions.resume },
    },
  },
})
