local mason_tool_installer = require("mason-tool-installer")
local tools = require("config.tools")

local function ensure_mason()
  local mason = require("mason")
  if not vim.g.__mason_setup_complete then
    mason.setup({
      max_concurrent_installers = 1,
    })
    vim.g.__mason_setup_complete = true
  end
end

ensure_mason()

mason_tool_installer.setup({
  ensure_installed = tools.tooling_install_list(),
  run_on_start = false,
  auto_update = false,
})
