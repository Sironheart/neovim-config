-- Key-triggered from pack.lua (<leader>xx); replace stub with real mapping after load

require('trouble').setup {}

vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' })
