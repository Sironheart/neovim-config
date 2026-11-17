local M = {
  managed_servers = {},
  unmanaged_servers = {
    mise = {},
  },
}
local managed_servers = M.managed_servers

managed_servers.astro = {}

managed_servers.cssls = {}

managed_servers.docker_compose_language_service = {}

managed_servers.dockerls = {}

managed_servers.gopls = {
  settings = {
    gopls = {
      hints = {
        assignVariableTypes = false,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
  completeUnimported = true,
}

managed_servers.html = {}

managed_servers.jsonls = {
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

managed_servers.lua_ls = { settings = { Lua = { workspace = { checkThirdParty = 'Disable' } } } }

managed_servers.phpactor = {
  init_options = {
    ['language_server_phpstan.enabled'] = false,
    ['language_server_psalm.enabled'] = false,
  },
}

managed_servers.pyright = {}

managed_servers.rust_analyzer = {
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        buildScripts = {
          enable = true,
        },
      },
      diagnostics = {
        styleLints = {
          enable = true,
        },
      },
      procMacro = {
        enable = true,
      },
      inlayHints = {
        bindingModeHints = { enable = false },
        chainingHints = { enable = true },
        closingBraceHints = { enable = true, minLines = 25 },
        closureReturnTypeHints = { enable = 'never' },
        lifetimeElisionHints = { enable = 'never', useParameterNames = false },
        maxLength = 25,
        parameterHints = { enable = true },
        reborrowHints = { enable = 'never' },
        renderColons = true,
        typeHints = {
          enable = true,
          hideClosureInitialization = false,
          hideNamedConstructor = false,
        },
      },
    },
  },
}

managed_servers.tailwindcss = {}

managed_servers.taplo = {}

managed_servers.terraformls = {}

local ts_ls_inlayhint_config = {
  inlayHints = {
    includeInlayEnumMemberValueHints = true,
    includeInlayParameterNameHints = 'all',
    includeInlayPropertyDeclarationTypeHints = true,
    includeInlayVariableTypeHints = true,
    includeInlayVariableTypeHintsWhenTypeMatchesName = true,
  },
}

managed_servers.ts_ls = {
  settings = {
    typescript = { ts_ls_inlayhint_config },
    javascript = { ts_ls_inlayhint_config },
  },
  single_file_support = false,
}

managed_servers.twiggy_language_server = {
  settings = {
    twiggy = {
      framework = 'symfony',
      phpExecutable = 'php',
      symfonyConsolePath = 'bin/console',
    },
  },
}

managed_servers.vue_ls = { init_options = { vue = { hybridMode = false } } }

managed_servers.yamlls = function()
  return require('kube_yaml_schema').yamlls_config {
    settings = {
      yaml = {
        format = {
          enable = false,
        },
      },
    },
  }
end

function M.enable_unmanaged()
  for name, config in pairs(M.unmanaged_servers) do
    if type(config) == 'function' then
      config = config()
    end
    if type(config) == 'table' then
      vim.lsp.config(name, config)
      vim.lsp.enable(name)
    end
  end
end

return M
