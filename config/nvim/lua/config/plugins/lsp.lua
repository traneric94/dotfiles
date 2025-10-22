local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local wk = require("which-key")

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  formatting = {
    format = function(_, item)
      local icons = {
        Text = "",
        Method = "",
        Function = "",
        Constructor = "",
        Field = "ﰠ",
        Variable = "",
        Class = "ﴯ",
        Interface = "",
        Module = "",
        Property = "ﰠ",
        Unit = "塞",
        Value = "",
        Enum = "",
        Keyword = "",
        Snippet = "",
        Color = "",
        File = "",
        Reference = "",
        Folder = "",
        EnumMember = "",
        Constant = "",
        Struct = "פּ",
        Event = "",
        Operator = "",
        TypeParameter = "",
      }
      item.kind = string.format("%s %s", icons[item.kind] or "", item.kind)
      return item
    end,
  },
  sources = cmp.config.sources({
    { name = "copilot" },
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
  experimental = {
    ghost_text = true,
  },
})

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    { name = "cmdline" },
  }),
})

vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_nvim_lsp = require("cmp_nvim_lsp")
capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

local tools = require("config.tools")

local function telescope_or(method, telescope_opts, fallback)
  return function(opts)
    local ok, builtin = pcall(require, "telescope.builtin")
    if ok and builtin[method] then
      local merged_opts = vim.tbl_deep_extend(
        "force",
        {},
        telescope_opts or {},
        opts or {}
      )
      builtin[method](merged_opts)
    else
      fallback(opts)
    end
  end
end

local on_attach = function(client, bufnr)
  local map = function(mode, lhs, rhs, desc_or_opts)
    local base_opts = { buffer = bufnr, silent = true }
    if type(desc_or_opts) == "table" then
      base_opts = vim.tbl_deep_extend("force", base_opts, desc_or_opts)
    else
      base_opts.desc = desc_or_opts
    end
    vim.keymap.set(mode, lhs, rhs, base_opts)
  end

  local implementations = telescope_or("lsp_implementations", { reuse_win = true }, function(call_opts)
    vim.lsp.buf.implementation(call_opts)
  end)

  local references = telescope_or("lsp_references", { show_line = false }, function(call_opts)
    vim.lsp.buf.references(call_opts)
  end)

  local type_definitions = telescope_or("lsp_type_definitions", { reuse_win = true }, function(call_opts)
    vim.lsp.buf.type_definition(call_opts)
  end)

  local definitions = telescope_or("lsp_definitions", { reuse_win = true }, function(call_opts)
    vim.lsp.buf.definition(call_opts)
  end)

  map("n", "gd", definitions, "Goto definition")
  map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
  map("n", "gi", implementations, "Goto implementation")
  map("n", "gr", references, { desc = "Goto references", nowait = true })
  for _, key in ipairs({ "gra", "grn", "gri", "grr", "grt" }) do
    pcall(vim.keymap.del, "n", key, { buffer = bufnr })
  end
  map("n", "K", vim.lsp.buf.hover, "Hover")
  map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
  map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
  map("n", "<leader>lf", function()
    vim.lsp.buf.format({ async = true })
  end, "Format buffer")
  map("n", "<leader>lD", type_definitions, "Goto type definition")
  map("n", "<leader>ls", vim.lsp.buf.signature_help, "Signature help")
  map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

  if client.name == "ts_ls" or client.name == "tsserver" then
    client.server_capabilities.documentFormattingProvider = false
  end

  if client.server_capabilities.documentHighlightProvider then
    local highlight = vim.api.nvim_create_augroup("LspDocumentHighlight" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      group = highlight,
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = highlight,
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end

  if wk.add then
    wk.add({
      { "<leader>l", group = "lsp", buffer = bufnr },
      { "<leader>la", desc = "Code action", buffer = bufnr },
      { "<leader>lD", desc = "Goto type definition", buffer = bufnr },
      { "<leader>lf", desc = "Format buffer", buffer = bufnr },
      { "<leader>lr", desc = "Rename symbol", buffer = bufnr },
      { "<leader>ls", desc = "Signature help", buffer = bufnr },
    })
  else
    wk.register({
      ["<leader>l"] = {
        name = "+lsp",
        a = "Code action",
        D = "Goto type definition",
        f = "Format buffer",
        r = "Rename symbol",
        s = "Signature help",
      },
    }, { buffer = bufnr })
  end
end

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

local mason_lspconfig = require("mason-lspconfig")

local servers = tools.servers

mason_lspconfig.setup({
  ensure_installed = servers,
})

local server_settings = {
  lua_ls = function()
    require("neodev").setup({})
    return {
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          diagnostics = { globals = { "vim" } },
        },
      },
    }
  end,
  gopls = function()
    return {
      settings = {
        gopls = {
          gofumpt = true,
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
            nilness = true,
            unusedwrite = true,
          },
        },
      },
    }
  end,
  yamlls = function()
    return {
      settings = {
        yaml = {
          schemas = {
            kubernetes = "*.yaml",
          },
          validate = true,
        },
      },
    }
  end,
}

local configured_servers = {}

for _, server in ipairs(servers) do
  local opts = {
    on_attach = on_attach,
    capabilities = vim.deepcopy(capabilities),
  }

  if server_settings[server] then
    local server_opts = server_settings[server]()
    opts = vim.tbl_deep_extend("force", opts, server_opts or {})
  end

  vim.lsp.config(server, opts)
  table.insert(configured_servers, server)
end

if #configured_servers > 0 then
  vim.lsp.enable(configured_servers)
end
