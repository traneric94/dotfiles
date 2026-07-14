local dap = require("dap")
local tools = require("config.tools")
local utils = require("config.utils")

local JS_ADAPTER = "pwa-node"
local JS_ADAPTER_EXECUTABLE = "js-debug-adapter"
local JS_ADAPTER_HOST = "127.0.0.1"
local JS_FILETYPES = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

utils.ensure_mason()

local mason_dap = require("mason-nvim-dap")
mason_dap.setup({
  ensure_installed = tools.dap_list(),
  automatic_installation = false,
  handlers = {
    js = function(config)
      config.name = JS_ADAPTER
      config.adapters = {
        type = "server",
        host = JS_ADAPTER_HOST,
        port = "${port}",
        executable = {
          command = vim.fn.exepath(JS_ADAPTER_EXECUTABLE),
          args = { "${port}", JS_ADAPTER_HOST },
        },
      }
      config.configurations = {
        {
          type = JS_ADAPTER,
          request = "launch",
          name = "JavaScript: Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          console = "integratedTerminal",
        },
        {
          type = JS_ADAPTER,
          request = "attach",
          name = "JavaScript: Attach to process",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
      }
      config.filetypes = JS_FILETYPES
      mason_dap.default_setup(config)
    end,
  },
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
