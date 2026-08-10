-- VimEnter: session keymaps; plugin attaches its own BufReadPre hooks

require('persistence').setup {
  branch = false,
}

vim.keymap.set('n', '<leader>qs', function()
  require('persistence').load()
end, { desc = 'Restore session' })

vim.keymap.set('n', '<leader>qS', function()
  require('persistence').select()
end, { desc = 'select a session to load' })

vim.keymap.set('n', '<leader>ql', function()
  require('persistence').load { last = true }
end, { desc = 'load last session' })

vim.keymap.set('n', '<leader>qd', function()
  require('persistence').stop()
end, { desc = 'Prevent session save on exit' })
