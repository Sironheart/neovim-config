return {
  {
    'saghen/blink.cmp',
    lazy = false,
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    version = 'v1.*',
    opts = {
      keymap = {
        preset = 'default',
        -- ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        -- ['<C-e>'] = { 'hide' },
        -- ['<C-y>'] = { 'select_and_accept' },
        --
        -- ['<C-p>'] = { 'select_prev', 'fallback' },
        -- ['<C-n>'] = { 'select_next', 'fallback' },
        --
        -- ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        -- ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        --
        -- ['<Tab>'] = { 'snippet_forward', 'fallback' },
        -- ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      },
      signature = { enabled = true },
      sources = {
        default = { 'lsp', 'path' },
      },
      completion = {
        documentation = {
          auto_show = true,
        },
      },
    },
  },
}
