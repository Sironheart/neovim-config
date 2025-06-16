return {
  {
    'olimorris/codecompanion.nvim',
    opts = {
      display = {
        diff = {
          enabled = true,
          close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
          layout = 'vertical', -- vertical|horizontal split for default provider
          opts = { 'internal', 'filler', 'closeoff', 'algorithm:patience', 'followwrap', 'linematch:120' },
          provider = 'default', -- default|mini_diff
        },
      },
      strategies = {
        chat = {
          tools = {
            opts = {
              auto_submit_errors = true,
              auto_submit_success = true,
            },
          },
          slash_commands = {
            ['file'] = {
              -- Location to the slash command in CodeCompanion
              callback = 'strategies.chat.slash_commands.file',
              description = 'Select a file using Snacks',
              opts = {
                provider = 'snacks',
                contains_code = true,
              },
            },
          },
        },
      },
      extensions = {
        mcphub = {
          callback = 'mcphub.extensions.codecompanion',
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
        vectorcode = {
          opts = {
            add_tool = true,
          },
        },
      },
    },
    dependencies = {
      -- required
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',

      -- optional dependencies
      {
        'Davidyz/VectorCode', -- Index and search code in your repositories
        version = '*',
        build = 'pipx upgrade vectorcode',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
      {
        'ravitemer/mcphub.nvim', -- Manage MCP servers
        cmd = 'MCPHub',
        build = 'npm install -g mcp-hub@latest',
        opts = {},
      },
    },
    keys = {
      { '<leader>aic', '<cmd>CodeCompanionChat<cr>', desc = 'AI Chat' },
    },
  },
}
