-- BufReadPre / BufNewFile: mason + lsp-setup + conform

require('mason').setup {}
require('fidget').setup {}

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

local language_servers = require 'custom.language-server'

require('lsp-setup').setup {
  servers = language_servers.managed_servers,
  on_attach = function() end, -- Conform owns format-on-save.
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
}

language_servers.enable_unmanaged()

require('conform').setup {
  formatters_by_ft = {
    elixir = { 'mix' },
    go = { 'goimports', 'gofmt' },
    java = { 'palantir-java-format' },
    javascript = { 'oxfmt' },
    javascriptreact = { 'oxfmt' },
    json = { 'oxfmt' },
    just = { 'just' },
    kotlin = { 'ktfmt' },
    lua = { 'stylua' },
    php = { 'php_cs_fixer' },
    python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
    rust = { 'rustfmt' },
    terraform = { 'tofu_fmt' },
    toml = function(bufnr)
      local filename = vim.api.nvim_buf_get_name(bufnr)
      local stem = vim.fs.basename(filename):gsub('^%.', ''):gsub('%.toml$', '')
      local parent = vim.fs.basename(vim.fs.dirname(filename))
      local directory = parent == 'conf.d' and vim.fs.basename(vim.fs.dirname(vim.fs.dirname(filename))) or parent
      if
        stem == 'mise'
        or stem:match '^mise%.'
        or ((directory == 'mise' or directory == '.mise') and (parent == 'conf.d' or stem == 'config' or stem:match '^config%.'))
      then
        return { 'mise' }
      end
      return { 'taplo' }
    end,
    typescript = { 'oxfmt' },
    typescriptreact = { 'oxfmt' },
    vue = { 'oxfmt' },
    yaml = { 'oxfmt' },
  },
  formatters = {
    mise = {
      command = 'mise',
      args = { 'fmt', '--stdin' },
      stdin = true,
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = 'never',
  },
  notify_no_formatters = true,
}
