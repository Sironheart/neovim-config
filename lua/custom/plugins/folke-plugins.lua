return {
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {
      branch = false,
    },
    keys = {
      {
        '<leader>qs',
        function()
          require('persistence').load()
        end,
        desc = 'Restore session',
      },
      {
        '<leader>qS',
        function()
          require('persistence').select()
        end,
        desc = 'select a session to load',
      },
      {
        '<leader>ql',
        function()
          require('persistence').load { last = true }
        end,
        desc = 'load last session',
      },
      {
        '<leader>qd',
        function()
          require('persistence').stop()
        end,
        desc = 'Prevent session save on exit',
      },
    },
  },

  {
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
          local output = vim.fn.system 'git rev-parse --is-inside-work-tree >/dev/null'

          if vim.v.shell_error == 0 and output:match 'true' ~= nil then
            snacks.picker.git_files { untracked = true }
          else
            snacks.picker.files()
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
  },

  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },

  {
    'folke/lazydev.nvim',
    dependencies = {
      { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
    },
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'folke/trouble.nvim',
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = 'Trouble',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      plugins = {
        registers = false,
        spelling = { enabled = false },
      },
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode' },
        { '<leader>l', group = '[L]azy' },
        { '<leader>q', group = '[Q]uick Session Peristence' },
        { '<leader>o', group = '[O]il' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>x', group = 'Trouble' },
      },
    },
  },
}
