local ok, kulala = pcall(require, "kulala")
if not ok then return end

kulala.setup({
  default_env = "dev",
  debug = false,
  show_icons = "on_request",
  formatter = {
    json = { "jq", "." },
  },
  scratchpad_default_content = "# @env dev\n\nGET https://httpbin.org/get\n",
})
