local telescope = require("telescope")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")

local function project_prioritized_sorter()
  local sorter = sorters.get_generic_fuzzy_sorter()
  local original = sorter.scoring_function
  local cwd = vim.loop.cwd() or ""
  local normalized_cwd = cwd ~= "" and vim.fs.normalize(cwd) or ""

  local function extract_path(entry)
    return entry.path or entry.filename or entry.value or entry.text
  end

  local function within_cwd(path)
    if normalized_cwd == "" or not path or path == "" then
      return false
    end
    local normalized_path = vim.fs.normalize(path)
    if normalized_path == normalized_cwd then
      return true
    end
    local prefix = normalized_cwd
    if not prefix:match("/$") then
      prefix = prefix .. "/"
    end
    return normalized_path:sub(1, #prefix) == prefix
  end

  sorter.scoring_function = function(self, prompt, line, entry, ...)
    local score = original(self, prompt, line, entry, ...)
    if type(score) ~= "number" then
      return score
    end
    if within_cwd(extract_path(entry)) then
      score = score - 1000
    end
    return score
  end

  return sorter
end

telescope.setup({
  defaults = {
    generic_sorter = project_prioritized_sorter(),
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
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
})
telescope.load_extension("harpoon")
