local telescope = require("telescope")
local actions = require("telescope.actions")

telescope.setup({
  defaults = {
    generic_sorter = project_prioritized_sorter,
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-f>"] = actions.preview_scrolling_up,
        ["<C-b>"] = actions.preview_scrolling_down,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
      },
      n = {
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-x>"] = actions.select_horizontal,
        ["<C-v>"] = actions.select_vertical,
        ["<C-t>"] = actions.select_tab,
      },
    },
  },
  extensions = {
    frecency = {
      auto_validate = true,
      show_unindexed = false,
      default_workspace = "CWD",
    },
  },
})

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "frecency")
telescope.load_extension("harpoon")
