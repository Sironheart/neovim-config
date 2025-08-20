local excludes = {
  '**/.astro',
  '**/.terraform',
  '**/var/cache',
  '**/var/logs',
  '**/dist-types/',
  '.venv',
  '.elixir_ls',
  '.git',
  '.gradle',
  '.idea',
  '.pulumi',
  '.vscode',
  '.yarn',
  '\\.lock',
  '_build',
  'bin',
  'cover',
  'coverage',
  'dist',
  'node_modules',
  'out',
  'target',
  'vendor',
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
        require('snacks').picker.files {
          cmd = 'rg',
          hidden = true,
          exclude = excludes,
          ignored = true,
        }
      end,
      desc = 'Find Files',
    },
    {
      '<leader>sg',
      function()
        require('snacks').picker.grep {
          cmd = 'rg',
          hidden = true,
          exclude = excludes,
          ignored = true,
        }
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
