-- BufReadPre / BufNewFile: completion (paired with LSP stack in pack.lua)

require('blink.cmp').setup {
  keymap = {
    preset = 'default',
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
