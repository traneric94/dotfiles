local status_cmp, cmp = pcall(require, "cmp")
if not status_cmp then
  return
end

local luasnip = require("luasnip")
local status_autopairs, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
local wk_ok, wk = pcall(require, "which-key")

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

if status_autopairs then
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

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

local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

local on_attach = function(client, bufnr)
  local telescope_ok, telescope_builtin = pcall(require, "telescope.builtin")

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  local implementations = telescope_ok and function()
    telescope_builtin.lsp_implementations({ reuse_win = true })
  end or vim.lsp.buf.implementation

  local references = telescope_ok and function()
    telescope_builtin.lsp_references({ show_line = false })
  end or vim.lsp.buf.references

  local type_definitions = telescope_ok and telescope_builtin.lsp_type_definitions and function()
    telescope_builtin.lsp_type_definitions({ reuse_win = true })
  end or vim.lsp.buf.type_definition

  local definitions = telescope_ok and telescope_builtin.lsp_definitions and function()
    telescope_builtin.lsp_definitions({ reuse_win = true })
  end or vim.lsp.buf.definition

  map("n", "gd", definitions, "Goto definition")
  map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
  map("n", "gi", implementations, "Goto implementation")
  map("n", "gr", references, "Goto references")
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

  if client.name == "tsserver" then
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

  if wk_ok then
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

local mason_ok, mason = pcall(require, "mason")
if not mason_ok then
  return
end
mason.setup()

local mason_lsp_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lsp_ok then
  return
end

local servers = {
  "gopls",
  "lua_ls",
  "pyright",
  "tsserver",
  "rust_analyzer",
  "solargraph",
  "jsonls",
  "yamlls",
  "html",
  "cssls",
  "dockerls",
}

mason_lspconfig.setup({
  ensure_installed = servers,
})

local lspconfig = require("lspconfig")

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

for _, server in ipairs(servers) do
  local opts = {
    on_attach = on_attach,
    capabilities = vim.deepcopy(capabilities),
  }

  if server_settings[server] then
    local server_opts = server_settings[server]()
    opts = vim.tbl_deep_extend("force", opts, server_opts or {})
  end

  lspconfig[server].setup(opts)
end
