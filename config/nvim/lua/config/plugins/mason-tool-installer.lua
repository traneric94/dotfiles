local ok, mason_tool_installer = pcall(require, "mason-tool-installer")
if not ok then
  return
end

local tools = require("config.tools")

local mason_ok, mason = pcall(require, "mason")
if mason_ok and not mason.has_setup then
  mason.setup()
end

mason_tool_installer.setup({
  ensure_installed = tools.tooling_install_list(),
  run_on_start = true,
  start_delay = 1000,
  auto_update = false,
})
