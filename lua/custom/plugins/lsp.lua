return {
  {
    'mosheavni/yaml-companion.nvim',
    opts = {
      builtin_matchers = {
        kubernetes = { enabled = true },
        cloud_init = { enabled = true },
      },

      cluster_crds = {
        enabled = true,
        fallback = true,
      },
    },
    config = function(_, opts)
      local cfg = require('yaml-companion').setup(opts)
      vim.lsp.config('yamlls', cfg)
    end,
  },
  {
    'junnplus/lsp-setup.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',

      'saghen/blink.cmp',
      'folke/snacks.nvim',
    },
    opts = {
      servers = require 'custom.language-server',
      inlay_hints = { enabled = true },
      capabilities = require('blink.cmp').get_lsp_capabilities(),
      default_mappings = false,
      mappings = {
        gd = 'lua require"snacks".picker.lsp_definitions()',
        gr = 'lua require"snacks".picker.lsp_references()',
        gI = 'lua require"snacks".picker.lsp_implementations()',
        D = 'lua require"snacks".picker.lsp_type_definitions()',
        K = { cmd = vim.lsp.buf.hover, opts = { desc = 'Hover Documentation' } },
        ['<space>rn'] = { cmd = vim.lsp.buf.rename, opts = { desc = 'Rename' } },
        ['<space>ca'] = { cmd = vim.lsp.buf.code_action, opts = { desc = 'Code Action' } },
        ['[d'] = {
          cmd = function()
            vim.diagnostic.jump { count = -1, float = true }
          end,
          opts = { desc = 'Prev Diagnostic' },
        },
        [']d'] = {
          cmd = function()
            vim.diagnostic.jump { count = 1, float = true }
          end,
          opts = { desc = 'Next Diagnostic' },
        },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', opts = {} },
      -- { 'williamboman/mason-lspconfig.nvim', opts = { ensure_installed = {} } },
      -- { 'WhoIsSethDaniel/mason-tool-installer.nvim', opts = { ensure_installed = {} } },

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim',       opts = {} },

      -- For the capabilities
      'saghen/blink.cmp',
    },
    config = function()
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
