local dap = require("dap")
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

local mason_dap = require("mason-nvim-dap")
mason_dap.setup({
  ensure_installed = tools.dap_list(),
  automatic_installation = false,
})

local dapui = require("dapui")
dapui.setup({})

local dap_virtual_text = require("nvim-dap-virtual-text")
dap_virtual_text.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Debug keymaps live in config/keymaps.lua under "-- Debug (DAP)" so all
-- bindings are centralized. The handlers there pcall(require, "dap") to stay
-- safe if the plugin isn't loaded.
