local configs = require "nvchad.configs.lspconfig"

local on_attach = configs.on_attach
local on_init = configs.on_init
local capabilities = configs.capabilities

local lspconfig = require "lspconfig"

-- list of all LSPs to be configured
local servers = { "html", "cssls", "pyright", "clangd", "dockerls", "docker_compose_language_service" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

-- Java (JDTLS) is handled by nvim-java if installed, or we can add it here
-- lspconfig.jdtls.setup {
--   on_attach = on_attach,
--   on_init = on_init,
--   capabilities = capabilities,
-- }
