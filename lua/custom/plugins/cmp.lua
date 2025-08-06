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
      fuzzy = {
        sorts = {
          function(a, b)
            if (a.client_name == nil or b.client_name == nil) or (a.client_name == b.client_name) then
              return
            end
            return b.client_name == 'emmet_ls'
          end,
          'exact',
          -- defaults
          'score',
          'sort_text',
        },
      },
      sources = {
        providers = {
          snippets = {
            should_show_items = function(ctx)
              return ctx.trigger.initial_kind ~= 'trigger_character'
            end,
          },
        },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = {
          auto_show = true,
        },
      },
    },
  },
}
