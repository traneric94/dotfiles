local mason_tool_installer = require("mason-tool-installer")
local tools = require("config.tools")
local utils = require("config.utils")

utils.ensure_mason()

mason_tool_installer.setup({
  ensure_installed = tools.tooling_install_list(),
  run_on_start = false,
  auto_update = false,
})
