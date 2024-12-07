return {
  {
    {
      'MysticalDevil/inlay-hints.nvim',
      event = 'LspAttach',
      dependencies = { 'neovim/nvim-lspconfig' },
      opts = {},
    },
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

        -- Allows extra capabilities provided by nvim-cmp
        'hrsh7th/cmp-nvim-lsp',
      },
      config = function()
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
          callback = function(event)
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
            end

            -- Jump to the definition of the word under your cursor.
            --  This is where a variable was first declared, or where a function is defined, etc.
            --  To jump back, press <C-T>.
            map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

            map('gvd', function()
              require('telescope.builtin').lsp_definitions { jump_type = 'vsplit' }
            end, '[G]oto [D]efinition')

            map('gr', function()
              require('telescope.builtin').lsp_references { jump_type = true }
            end, '[G]oto [R]eferences')

            map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

            map('gvI', function()
              require('telescope.builtin').lsp_implementations { jump_type = 'vsplit' }
            end, '[G]oto [I]mplementation')

            map('<leader>D', function()
              require('telescope.builtin').lsp_type_definitions()
            end, 'Type [D]efinition')

            map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

            map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

            map('K', vim.lsp.buf.hover, 'Hover Documentation')

            map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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
          end,
        })

        require('mason').setup {
          PATH = 'prepend',
        }
        require('mason-lspconfig').setup {
          automatic_installation = false,
          ensure_installed = {
            'astro',
            'cssls',
            'elixirls',
            'emmet_ls',
            'gopls',
            'html',
            'jsonls',
            'lua_ls',
            'terraformls',
            'ts_ls',
            'volar',
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

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

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
          elixirls = { cmd = { 'elixir-ls' } },
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
          kotlin_language_server = {},
          lua_ls = { settings = { Lua = { hint = { enable = true }, workspace = { checkThirdParty = 'Disable' } } } },
          nil_ls = {},
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
          templ = {},
          terraformls = {},
          ts_ls = {
            settings = { typescript = { ts_ls_inlayhint_config }, javascript = { ts_ls_inlayhint_config } },
            root_dir = require('lspconfig.util').root_pattern('tsconfig.json', 'tsconfig.json', 'jsconfig.json'),
            single_file_support = false,
          },
          volar = { init_options = { vue = { hybridMode = false } } },
          yamlls = {},
        }

        for key, value in pairs(servers) do
          require('lspconfig')[key].setup(value)
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
        javascript = { 'deno', 'biome', 'prettierd', 'prettier', stop_after_first = true },
        json = { 'jq' },
        just = { 'just' },
        lua = { 'stylua' },
        markdown = { 'prettier' },
        nix = { 'alejandra' },
        rust = { 'rustfmt' },
        templ = { 'templ' },
        terraform = { 'tofu_fmt', 'terraform_fmt', stop_after_first = true },
        typescript = { 'deno', 'biome', 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettier' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    },
  },
}
