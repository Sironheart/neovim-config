local excludes = {
  '.git',
  'node_modules',
  'vendor',
  'target',
  '\\.lock',
}

return {

  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    image = { enabled = true },
    indent = { enabled = true },
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
        local opts = {
          hidden = true,
          exclude = excludes,
        }

        if snacks.git.get_root(vim.uv.cwd()) then
          snacks.picker.git_files(opts)
        else
          snacks.picker.files(opts)
        end
      end,
      desc = 'Find Files',
    },
    {
      '<leader>sg',
      function()
        local snacks = require 'snacks'
        local opts = {
          hidden = true,
          exclude = excludes,
        }

        if snacks.git.get_root(vim.uv.cwd()) then
          snacks.picker.git_grep(opts)
        else
          snacks.picker.grep(opts)
        end
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
        require('snacks').picker.recent {
          filter = {
            paths = {
              [vim.fn.getcwd()] = true,
            },
          },
        }
      end,
      desc = 'Search last files',
    },
  },
}
