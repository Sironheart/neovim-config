return {
  { 'tpope/vim-sleuth' },
  { 'JoosepAlviste/nvim-ts-context-commentstring', opts = { enable_autocmd = false } },
  { 'NoahTheDuke/vim-just', ft = { 'just' } },
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'stevearc/oil.nvim',
    opts = {
      columns = { 'icon' },
      watch_for_changes = true,
      view_options = {
        show_hidden = true,
      },
    },
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    keys = {
      { '<leader>oo', ':Oil<CR>', desc = 'Open file buffer' },
    },
  },
}
