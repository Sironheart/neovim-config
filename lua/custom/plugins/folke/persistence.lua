return {
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
}
