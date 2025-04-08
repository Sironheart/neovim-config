return {
  { 'tpope/vim-sleuth' },
  {
    'kylechui/nvim-surround',
    version = '^3.0.0', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    opt = {},
  },

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
      { '<leader>o', ':Oil<CR>', desc = 'Open file buffer' },
    },
  },
}
