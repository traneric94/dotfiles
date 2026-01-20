local M = {}

M.go_bin_path = function()
  local path = vim.g.go_bin_path or vim.fn.expand("$HOME/go/bin/")
  if not path:match("/$") then
    path = path .. "/"
  end
  return path
end

function M.go_format()
  if vim.bo.filetype ~= "go" then
    return
  end

  local file = vim.fn.expand("%:p")
  local gofmt = vim.fn.exepath("gofmt")
  if gofmt == "" then
    local fallback = M.go_bin_path() .. "gofmt"
    if vim.fn.filereadable(fallback) == 1 then
      gofmt = fallback
    else
      vim.notify("Go format failed: gofmt not found on PATH", vim.log.levels.ERROR)
      return
    end
  end

  local cmd = string.format("%s -w %s 2>&1", vim.fn.shellescape(gofmt), vim.fn.shellescape(file))
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Go format failed: " .. result, vim.log.levels.ERROR)
    return
  end
  vim.cmd("edit!")
end

function M.toggle_test_file()
  local file = vim.fn.expand("%:p")
  local ext = vim.fn.expand("%:e")
  local transforms

  if ext == "rb" then
    transforms = {
      { pattern = "_spec%.rb$", replace = ".rb", from_dir = "/spec/", to_dir = "/lib/" },
      { pattern = "%.rb$", replace = "_spec.rb", from_dir = "/lib/", to_dir = "/spec/" },
    }
  elseif ext == "go" then
    transforms = {
      { pattern = "_test%.go$", replace = ".go" },
      { pattern = "%.go$", replace = "_test.go" },
    }
  elseif vim.tbl_contains({ "ts", "tsx", "js", "jsx" }, ext) then
    transforms = {
      { pattern = ("%.test%." .. ext .. "$"), replace = ("." .. ext) },
      { pattern = ("%." .. ext .. "$"), replace = (".test." .. ext) },
    }
  end

  if transforms then
    for _, transform in ipairs(transforms) do
      if file:match(transform.pattern) then
        local target = file:gsub(transform.pattern, transform.replace)
        if transform.from_dir and transform.to_dir then
          target = target:gsub(transform.from_dir, transform.to_dir)
        end
        vim.cmd("edit " .. vim.fn.fnameescape(target))
        vim.notify("Toggled to: " .. vim.fn.fnamemodify(target, ":t"), vim.log.levels.INFO)
        return
      end
    end
  end

  vim.notify("No test pattern for: " .. ext, vim.log.levels.WARN)
end

function M.open_pull_request()
  local line_num = vim.fn.line(".")
  local blame = vim.fn.systemlist(string.format("git blame -L%d,%d --porcelain %s", line_num, line_num, vim.fn.expand("%")))
  if not blame or #blame == 0 then
    vim.notify("Could not get commit hash for current line", vim.log.levels.WARN)
    return
  end

  local commit_hash = vim.split(blame[1], "%s+")[1]
  if not commit_hash or #commit_hash ~= 40 then
    vim.notify("Could not get commit hash for current line", vim.log.levels.WARN)
    return
  end

  local pr_num = vim.fn.system(string.format([[gh pr list --search "%s" --json number --jq '.[0].number // empty']], commit_hash))
  pr_num = vim.trim(pr_num)

  if pr_num ~= "" and pr_num ~= "null" then
    vim.notify(string.format("Opening PR #%s for commit %s", pr_num, commit_hash:sub(1, 7)))
    vim.fn.jobstart({ "gh", "pr", "view", pr_num, "--web" }, { detach = true })
  else
    vim.notify("No PR found for commit " .. commit_hash:sub(1, 7), vim.log.levels.INFO)
  end
end

function M.fold_imports()
  local ft = vim.bo.filetype
  local patterns = {
    go = "^%s*import%s*%(",
    ruby = "^%s*require",
    python = "^%s*(import|from)%s",
  }
  local ts_filetypes = {
    typescriptreact = true,
    typescript = true,
    javascript = true,
    javascriptreact = true,
  }

  local pattern = patterns[ft]
  if not pattern and ts_filetypes[ft] then
    pattern = "^%s*import%s+.*from"
  end

  if not pattern then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local saved_fdm = vim.wo.foldmethod
  vim.wo.foldmethod = "manual"

  local start_line = nil
  for idx, line in ipairs(lines) do
    if line:match(pattern) then
      start_line = start_line or idx
    elseif start_line and line:match("^%s*$") then
      -- still part of import block
    elseif start_line then
      if idx > start_line then
        vim.cmd(string.format("%d,%dfold", start_line, idx - 1))
      end
      start_line = nil
    end
  end

  if start_line then
    vim.cmd(string.format("%d,%dfold", start_line, #lines))
  end

  vim.wo.foldmethod = saved_fdm
end

function M.clear_quickfix()
  vim.fn.setqflist({})
end

vim.api.nvim_create_user_command("FoldImports", function()
  M.fold_imports()
end, {})

vim.api.nvim_create_user_command("GoFormat", function()
  M.go_format()
end, {})

vim.api.nvim_create_user_command("ToggleTestFile", function()
  M.toggle_test_file()
end, {})

vim.api.nvim_create_user_command("OpenPullRequest", function()
  M.open_pull_request()
end, {})

return M
