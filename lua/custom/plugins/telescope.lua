return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  keys = {
    { '<leader>sk', require('telescope.builtin').keymaps, desc = '[S]earch [K]eymaps' },
    { '<leader>sf', require('telescope.builtin').find_files, desc = '[S]earch [F]iles' },
    { '<leader>sg', require('telescope.builtin').live_grep, desc = '[S]earch using [G]rep' },
    { '<leader>sr', require('telescope.builtin').resume, desc = '[S]earch [R]esume' },
    { '<leader>sb', require('telescope.builtin').buffers, desc = '[S]earch existing [b]uffers' },
    { '<leader><space>', require('telescope.builtin').oldfiles, desc = '[ ] Find last opened files' },
  },
  config = function()
    local telescope = require 'telescope'
    local telescopeConfig = require 'telescope.config'
    -- Clone the default Telescope configuration
    local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

    -- I want to search in hidden/dot files.
    table.insert(vimgrep_arguments, '--hidden')
    -- I don't want to search in the `.git` directory.
    table.insert(vimgrep_arguments, '--glob')
    table.insert(vimgrep_arguments, '!**/.git/*')

    telescope.setup {
      defaults = {
        vimgrep_arguments = vimgrep_arguments,

        file_ignore_patterns = {
          '.lock',
          '.next',
          '.sl',
          'Caches',
          '.elixir_ls',
          '.fleet',
          '.git/',
          '.idea',
          '.vscode',
          '.yarn',
          '/nix',
          '_build',
          'node_modules',
        },
        mappings = {
          i = {
            ['<C-u>'] = false,
            ['<C-d>'] = false,
          },
        },
      },
      hidden = true,
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown {},
        },
        fzf = {
          fuzzy = true,
          case_mode = 'ignore_case',
        },
      },
      pickers = {
        find_files = {
          find_command = { 'rg', '--files', '--hidden', '--trim' },
        },
      },
    }

    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'ui-select')
    pcall(telescope.load_extension, 'notify')
  end,
}
