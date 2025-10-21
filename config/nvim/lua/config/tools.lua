local M = {}

---@class ToolSpec
---@field filetypes string[]
---@field formatters string[]?
---@field linters string[]?
---@field daps string[]?

---@type table<string, ToolSpec>
M.server_specs = {
  gopls = {
    filetypes = { "go" },
    formatters = { "gofumpt" },
    linters = { "golangci-lint" },
    daps = { "delve" },
  },
  lua_ls = {
    filetypes = { "lua" },
    formatters = { "stylua" },
    linters = { "luacheck" },
  },
  pyright = {
    filetypes = { "python" },
    formatters = { "black" },
    linters = { "ruff" },
    daps = { "debugpy" },
  },
  ts_ls = {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    formatters = { "prettierd" },
    linters = { "eslint_d" },
    daps = { "js-debug-adapter" },
  },
  rust_analyzer = {
    filetypes = { "rust" },
    formatters = { "rustfmt" },
    daps = { "codelldb" },
  },
  ruby_lsp = {
    filetypes = { "ruby" },
    formatters = { "rubocop" },
    linters = { "rubocop" },
  },
  jsonls = {
    filetypes = { "json", "jsonc" },
    formatters = { "prettierd" },
  },
  yamlls = {
    filetypes = { "yaml" },
    formatters = { "yamlfmt" },
    linters = { "yamllint" },
  },
  html = {
    filetypes = { "html" },
    formatters = { "prettierd" },
  },
  cssls = {
    filetypes = { "css", "scss", "less" },
    formatters = { "prettierd" },
    linters = { "stylelint" },
  },
  dockerls = {
    filetypes = { "dockerfile" },
    linters = { "hadolint" },
  },
  intelephense = {
    filetypes = { "php" },
    formatters = { "php-cs-fixer" },
    linters = { "phpcs" },
    daps = { "php-debug-adapter" },
  },
}

M.servers = vim.tbl_keys(M.server_specs)
table.sort(M.servers)

local function unique(list)
  local seen = {}
  local result = {}
  for _, item in ipairs(list) do
    if item ~= nil and item ~= "" and not seen[item] then
      seen[item] = true
      table.insert(result, item)
    end
  end
  table.sort(result)
  return result
end

local function collect(kind)
  local collected = {}
  for _, spec in pairs(M.server_specs) do
    for _, entry in ipairs(spec[kind] or {}) do
      collected[entry] = true
    end
  end
  local keys = vim.tbl_keys(collected)
  table.sort(keys)
  return keys
end

local function map_by_ft(kind)
  local mappings = {}
  for _, spec in pairs(M.server_specs) do
    local tools = spec[kind] or {}
    if #tools > 0 then
      for _, ft in ipairs(spec.filetypes or {}) do
        local bucket = mappings[ft] or {}
        for _, tool in ipairs(tools) do
          local already_present = false
          for _, existing in ipairs(bucket) do
            if existing == tool then
              already_present = true
              break
            end
          end
          if not already_present then
            table.insert(bucket, tool)
          end
        end
        mappings[ft] = bucket
      end
    end
  end
  for ft, tools in pairs(mappings) do
    mappings[ft] = unique(tools)
  end
  return mappings
end

function M.formatter_list()
  return collect("formatters")
end

function M.linter_list()
  return collect("linters")
end

function M.dap_list()
  return collect("daps")
end

function M.formatters_by_ft()
  return map_by_ft("formatters")
end

function M.linters_by_ft()
  return map_by_ft("linters")
end

function M.tooling_install_list()
  local combined = {}
  for _, name in ipairs(M.formatter_list()) do
    table.insert(combined, name)
  end
  for _, name in ipairs(M.linter_list()) do
    table.insert(combined, name)
  end
  return unique(combined)
end

return M
