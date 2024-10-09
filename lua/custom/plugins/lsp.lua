return {
  {
    {
      'Bilal2453/luvit-meta',
      lazy = true,
    },
    {
      -- Main LSP Configuration
      'neovim/nvim-lspconfig',
      dependencies = {
        -- Automatically install LSPs and related tools to stdpath for Neovim
        { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',

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

            -- The following code creates a keymap to toggle inlay hints in your
            -- code, if the language server you are using supports them
            --
            -- This may be unwanted, since they displace some of your code
            if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
              map('<leader>th', function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
              end, '[T]oggle Inlay [H]ints')
            end
          end,
        })

        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

        local servers = {
          astro = {},
          cssls = {},
          denols = {},
          docker_compose_language_service = {},
          dockerls = {
            settings = {
              docker = {
                languageserver = {
                  formatter = { ignoreMultilineInstructions = true },
                },
              },
            },
            filetypes = { 'dockerfile', 'containerfile' },
          },
          emmet_ls = {
            options = {
              ['jsx.enabled'] = true,
            },
            filetypes = { 'html', 'templ', 'liquid', 'mjml' },
          },
          elixirls = {
            cmd = { 'elixir-ls' },
          },
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
          },
          html = {},
          java_language_server = {},
          jsonls = {},
          kotlin_language_server = {},
          lua_ls = {
            settings = {
              Lua = {
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
                completion = { callSnippet = 'Replace' },
              },
            },
          },
          nil_ls = {},
          ocamllsp = {},
          terraformls = {},
          tsserver = {},
          volar = {
            init_options = {
              vue = {
                hybridMode = false,
              },
            },
          },
          yamlls = {},
        }

        require('mason').setup()

        require('mason-lspconfig').setup {
          handlers = {
            function(server_name)
              local server = servers[server_name] or {}
              -- This handles overriding only values explicitly passed
              -- by the server configuration above. Useful when disabling
              -- certain features of an LSP (for example, turning off formatting for ts_ls)
              server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
              require('lspconfig')[server_name].setup(server)
            end,
          },
        }
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
        go = { 'goimports', 'gofmt' },
        javascript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        json = { 'jq' },
        just = { 'just' },
        lua = { 'stylua' },
        markdown = { 'prettier' },
        nix = { 'alejandra' },
        ocaml = { 'ocamlformat' },
        terraform = { 'terraform_fmt' },
        typescript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettier' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    },
  },
}
