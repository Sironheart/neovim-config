return {
  {
    {
      -- Main LSP Configuration
      'neovim/nvim-lspconfig',
      dependencies = {
        -- Automatically install LSPs and related tools to stdpath for Neovim
        { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
        'williamboman/mason-lspconfig.nvim',

        -- Useful status updates for LSP.
        -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
        { 'j-hui/fidget.nvim', opts = {} },

        -- For the capabilities
        'saghen/blink.cmp',
      },
      config = function()
        vim.lsp.set_log_level 'off'
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
          callback = function(event)
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
            end

            map('gd', require('snacks').picker.lsp_definitions, '[G]oto [D]efinition')
            map('gr', require('snacks').picker.lsp_references, '[G]oto [R]eferences')
            map('gI', require('snacks').picker.lsp_implementations, '[G]oto [I]mplementation')
            map('<leader>D', require('snacks').picker.lsp_type_definitions, 'Type [D]efinition')
            map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
            map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
            map('K', vim.lsp.buf.hover, 'Hover Documentation')
            map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
              local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
              vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
              })

              vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
              })

              vim.api.nvim_create_autocmd('LspDetach', {
                group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                callback = function(event2)
                  vim.lsp.buf.clear_references()
                  vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
                end,
              })
            end

            if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
              map('<leader>th', function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
              end, '[T]oggle Inlay [H]ints')
            end
          end,
        })

        vim.diagnostic.config {
          severity_sort = true,
          float = { border = 'rounded', source = 'if_many' },
          underline = { severity = vim.diagnostic.severity.ERROR },
          signs = vim.g.have_nerd_font and {
            text = {
              [vim.diagnostic.severity.ERROR] = '󰅚 ',
              [vim.diagnostic.severity.WARN] = '󰀪 ',
              [vim.diagnostic.severity.INFO] = '󰋽 ',
              [vim.diagnostic.severity.HINT] = '󰌶 ',
            },
          } or {},
          virtual_text = {
            source = 'if_many',
            spacing = 2,
            format = function(diagnostic)
              local diagnostic_message = {
                [vim.diagnostic.severity.ERROR] = diagnostic.message,
                [vim.diagnostic.severity.WARN] = diagnostic.message,
                [vim.diagnostic.severity.INFO] = diagnostic.message,
                [vim.diagnostic.severity.HINT] = diagnostic.message,
              }
              return diagnostic_message[diagnostic.severity]
            end,
          },
        }

        require('mason').setup {
          PATH = 'append',
        }
        require('mason-lspconfig').setup {
          automatic_enable = false,
          automatic_installation = false,
          ensure_installed = {
            'astro',
            'cssls',
            'emmet_ls',
            'gopls',
            'html',
            'jsonls',
            'lua_ls',
            'terraformls',
            'ts_ls',
            'yamlls',
          },
        }

        local ts_ls_inlayhint_config = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayParameterNameHints = 'all',
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
          },
        }

        local servers = {
          astro = {},
          cssls = {},
          denols = {
            settings = {
              deno = {
                inlayHints = {
                  enumMemberValues = { enabled = true },
                  parameterNames = { enabled = 'all', suppressWhenArgumentMatchesName = true },
                  propertyDeclarationTypes = { enabled = true },
                  variableTypes = { enabled = true, suppressWhenTypeMatchesName = true },
                },
              },
            },
            root_dir = require('lspconfig.util').root_pattern('deno.json', 'deno.jsonc'),
            single_file_support = false,
          },
          docker_compose_language_service = {},
          dockerls = {},
          emmet_ls = { options = { ['jsx.enabled'] = true } },
          gleam = {},
          gopls = {
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
          },
          html = {},
          jsonls = {},
          kotlin_lsp = {},
          lua_ls = { settings = { Lua = { hint = { enable = true }, workspace = { checkThirdParty = 'Disable' } } } },
          nil_ls = {},
          pyright = {},
          rust_analyzer = {
            settings = {
              ['rust-analyzer'] = {
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
          },
          tailwindcss = {},
          terraformls = {},
          ts_ls = {
            settings = { typescript = { ts_ls_inlayhint_config }, javascript = { ts_ls_inlayhint_config } },
            root_dir = require('lspconfig.util').root_pattern('tsconfig.json', 'tsconfig.json', 'jsconfig.json'),
            single_file_support = false,
          },
          -- vue_ls = { init_options = { vue = { hybridMode = false } } },
          yamlls = {},
        }

        local lspconfig = require 'lspconfig'
        local blink = require 'blink.cmp'

        for server, config in pairs(servers) do
          config.capabilities = blink.get_lsp_capabilities(config.capabilities)
          -- enable inlay hints when available
          -- config.on_attach = function(client, bufnr)
          --   if client.server_capabilities.inlayHintProvider then
          --     vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          --   end
          -- end
          lspconfig[server].setup(config)
        end
      end,
    },
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      formatters_by_ft = {
        ['_'] = { 'prettier' },
        cue = { 'cuefmt' },
        elixir = { 'mix' },
        go = { 'goimports', 'gofmt' },
        javascript = { 'biome', 'prettierd', 'deno', 'prettier', stop_after_first = true },
        json = { 'jq' },
        just = { 'just' },
        lua = { 'stylua' },
        nix = { 'alejandra' },
        python = { 'ruff' },
        rust = { 'rustfmt' },
        terraform = { 'tofu_fmt', 'terraform_fmt', stop_after_first = true },
        typescript = { 'biome', 'prettierd', 'deno', 'prettier', stop_after_first = true },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
      notify_no_formatters = false,
    },
  },
}
