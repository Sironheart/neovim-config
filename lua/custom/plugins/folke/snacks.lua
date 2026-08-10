-- Eager: picker / notifier / statuscolumn used from first moment

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

require('snacks').setup {
  image = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  lazygit = { enabled = true },
  notifier = { enabled = true, timeout = 5000 },
  picker = { enabled = true },
  scope = { enabled = true },
  statuscolumn = { enabled = true },
}

vim.keymap.set('n', '<leader>lg', function()
  Snacks.lazygit()
end, { desc = 'Open lazygit' })

vim.keymap.set('n', '<leader>sf', function()
  Snacks.picker.files {
    cmd = 'rg',
    hidden = true,
    exclude = excludes,
    ignored = true,
  }
end, { desc = 'Find Files' })

vim.keymap.set('n', '<leader>sg', function()
  Snacks.picker.grep {
    cmd = 'rg',
    hidden = true,
    exclude = excludes,
    ignored = true,
  }
end, { desc = 'Search Grep' })

vim.keymap.set('n', '<leader>sb', function()
  Snacks.picker.buffers()
end, { desc = 'Search Buffers' })

vim.keymap.set('n', '<leader>sr', function()
  Snacks.picker.resume()
end, { desc = 'Search Resume' })

vim.keymap.set('n', '<leader>sk', function()
  Snacks.picker.keymaps()
end, { desc = 'Search Keymap' })

vim.keymap.set('n', '<leader><space>', function()
  Snacks.picker.recent {
    filter = {
      paths = {
        [vim.fn.getcwd()] = true,
      },
    },
  }
end, { desc = 'Search last files' })
