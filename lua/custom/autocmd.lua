-- Start insert mode when opening a git commit message
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  callback = function()
    vim.cmd 'startinsert'
  end,
})
