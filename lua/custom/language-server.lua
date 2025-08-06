local M = {}

M.astro = {}

M.cssls = {}

M.docker_compose_language_service = {}

M.dockerls = {}

M.emmet_ls = { options = { ['jsx.enabled'] = true } }

M.gleam = {}

M.gopls = {
  settings = {
    gopls = {
      hints = {
        assignVariableTypes = true,
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

M.html = {}

M.jsonls = {}

M.kotlin_lsp = {}

M.lua_ls = { settings = { Lua = { workspace = { checkThirdParty = 'Disable' } } } }

M.phpactor = {
  init_options = {
    ['language_server_phpstan.enabled'] = false,
    ['language_server_psalm.enabled'] = false,
  },
}

M.pyright = {}

M.rust_analyzer = {
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

M.tailwindcss = {}

M.taplo = {}

M.terraformls = {}

local ts_ls_inlayhint_config = {
  inlayHints = {
    includeInlayEnumMemberValueHints = true,
    includeInlayParameterNameHints = 'all',
    includeInlayPropertyDeclarationTypeHints = true,
    includeInlayVariableTypeHints = true,
    includeInlayVariableTypeHintsWhenTypeMatchesName = true,
  },
}

M.ts_ls = {
  settings = {
    typescript = { ts_ls_inlayhint_config },
    javascript = { ts_ls_inlayhint_config },
  },
  single_file_support = false,
}

M.twiggy_language_server = {
  settings = {
    twiggy = {
      framework = 'symfony',
      phpExecutable = 'php',
      symfonyConsolePath = 'bin/console',
    },
  },
}

M.vue_ls = { init_options = { vue = { hybridMode = false } } }

M.yamlls = {}

return M
