return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = '<C-y>',
        next = '<C-]>',
        prev = '<C-[',
        dismiss = '<C-c>',
      },
    },
    panel = {
      enabled = false,
    },
    filetypes = {
      ['*'] = true,
    },
  },
  -- config = function(_, opts)
  -- require('ocopilot').setup(opts)
  -- local cmp = require 'cmp'
  --
  -- if not cmp then
  --   return
  -- end
  --
  -- cmp.event:on('menu_opened', function()
  --   vim.b.copilot_suggestion_hidden = true
  -- end)
  --
  -- require('cmp').event:on('menu_closed', function()
  --   vim.b.copilot_suggestion_hidden = false
  -- end)
  -- end,
}
