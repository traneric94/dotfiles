local status_ok, copilot = pcall(require, "copilot")
if not status_ok then
  return
end

copilot.setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})

local cmp_status, copilot_cmp = pcall(require, "copilot_cmp")
if cmp_status then
  copilot_cmp.setup()
end
