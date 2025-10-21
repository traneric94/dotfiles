local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
  return
end

local tools = require("config.tools")

local mason_dap_ok, mason_dap = pcall(require, "mason-nvim-dap")
if mason_dap_ok then
  mason_dap.setup({
    ensure_installed = tools.dap_list(),
    automatic_installation = false,
  })
end

local dapui_ok, dapui = pcall(require, "dapui")
if dapui_ok then
  dapui.setup({})
end

local vt_ok, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
if vt_ok then
  dap_virtual_text.setup()
end

if dapui_ok then
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
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
  if dapui_ok then
    dapui.toggle({})
  end
end, "Debug: toggle UI")
