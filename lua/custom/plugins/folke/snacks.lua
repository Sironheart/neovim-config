return {

  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    indent = { enabled = true },
    image = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true },
    picker = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
  },
  keys = {
    {
      '<leader>lg',
      function()
        require('snacks').lazygit.open()
      end,
      desc = 'Open lazygit',
    },
    {
      '<leader>sf',
      function()
        local snacks = require 'snacks'
        local output = vim.fn.system 'git rev-parse --is-inside-work-tree 2>/dev/null'

        if vim.v.shell_error == 0 and output:match 'true' ~= nil then
          snacks.picker.git_files { untracked = true }
        else
          snacks.picker.files { hidden = true }
        end
      end,
      desc = 'Find Files',
    },
    {
      '<leader>sg',
      function()
        require('snacks').picker.grep()
      end,
      desc = 'Search Grep',
    },
    {
      '<leader>sb',
      function()
        require('snacks').picker.buffers()
      end,
      desc = 'Search Buffers',
    },
    {
      '<leader>sr',
      function()
        require('snacks').picker.resume()
      end,
      desc = 'Search Resume',
    },
    {
      '<leader>sk',
      function()
        require('snacks').picker.keymaps()
      end,
      desc = 'Search Keymap',
    },
    {
      '<leader><space>',
      function()
        require('snacks').picker.recent()
      end,
      desc = 'Search last files',
    },
  },
}
