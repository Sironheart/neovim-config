function indexOf(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

return {
  {
    'aaronshifman/auto-k8s.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    opts = {},
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

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

      local servers = require 'custom.language-server'

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local ignore_install = { 'gleam' }
      local ensure_installed = vim.tbl_keys(servers or {})

      for _, v in pairs(ignore_install) do
        table.remove(ensure_installed, indexOf(ensure_installed, v))
      end

      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })

      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }

      require('mason-lspconfig').setup {
        automatic_enable = true,
        ensure_installed = {},
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            vim.lsp.config(server_name, server.config or {})
            -- require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      formatters_by_ft = {
        ['_'] = { 'prettier' },
        elixir = { 'mix' },
        go = { 'goimports', 'gofmt' },
        javascript = { 'biome', 'prettier', stop_after_first = true },
        json = { 'jq' },
        just = { 'just' },
        lua = { 'stylua' },
        php = { 'php_cs_fixer' },
        python = { 'ruff' },
        rust = { 'rustfmt' },
        terraform = { 'tofu_fmt', 'terraform_fmt', stop_after_first = true },
        toml = { 'taplo' },
        typescript = { 'biome', 'prettier', stop_after_first = true },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
      notify_no_formatters = false,
    },
  },
}
