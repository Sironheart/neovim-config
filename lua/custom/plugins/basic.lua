-- VimEnter (VeryLazy): editing helpers that are fine a tick after UI is up

require('nvim-surround').setup {}

require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

require('oil').setup {
  columns = { 'icon' },
  watch_for_changes = true,
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '<leader>o', ':Oil<CR>', { desc = 'Open file buffer' })
