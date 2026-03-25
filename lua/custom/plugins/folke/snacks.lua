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
    notifier = { enabled = true, timeout = 5000 },
    picker = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
  },
  keys = {
    {
      '<leader>lg',
      function()
        Snacks.lazygit()
      end,
      desc = 'Open lazygit',
    },
    {
      '<leader>sf',
      function()
        Snacks.picker.files {
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
        Snacks.picker.grep {
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
        Snacks.picker.buffers()
      end,
      desc = 'Search Buffers',
    },
    {
      '<leader>sr',
      function()
        Snacks.picker.resume()
      end,
      desc = 'Search Resume',
    },
    {
      '<leader>sk',
      function()
        Snacks.picker.keymaps()
      end,
      desc = 'Search Keymap',
    },
    {
      '<leader><space>',
      function()
        Snacks.picker.recent {
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
