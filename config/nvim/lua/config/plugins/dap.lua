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

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader>db", dap.toggle_breakpoint, "Debug: toggle breakpoint")
map("<leader>dc", dap.continue, "Debug: continue")
map("<leader>di", dap.step_into, "Debug: step into")
map("<leader>do", dap.step_over, "Debug: step over")
map("<leader>dO", dap.step_out, "Debug: step out")
map("<leader>dr", dap.repl.open, "Debug: open REPL")
map("<leader>dl", dap.run_last, "Debug: run last")
map("<leader>dk", function()
  if dap.session() then
    dap.terminate()
  end
end, "Debug: terminate")
map("<leader>du", function()
  dapui.toggle({})
end, "Debug: toggle UI")
