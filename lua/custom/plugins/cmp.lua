-- Eager: completion (blink also provides cmdline completion, must beat first `:`)

require('blink.cmp').setup {
  keymap = {
    preset = 'default',
  },
  cmdline = {
    completion = { menu = { auto_show = true } },
  },
  signature = { enabled = true },
  sources = {
    default = { 'lsp', 'path' },
  },
  completion = {
    documentation = {
      auto_show = true,
    },
    ghost_text = { enabled = true },
  },
}
