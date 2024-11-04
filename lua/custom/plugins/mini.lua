return {
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.basics').setup {
        mappings = {
          basic = true,
          windows = true,
          move_with_alt = true,
        },
      }
      require('mini.ai').setup { n_lines = 500 }
      require('mini.indentscope').setup()
      require('mini.move').setup()
      require('mini.trailspace').setup()

      require('mini.surround').setup()
      require('mini.pairs').setup()

      require('mini.statusline').setup { use_icons = vim.g.have_nerd_font }
    end,
  },
}
