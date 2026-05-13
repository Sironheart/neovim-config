return {
  'nvim-lualine/lualine.nvim',
  opts = {
    options = {
      theme = 'papercolor_dark',
    },
    sections = {
      -- lualine_w = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'lsp_status' },
    },
  },
}
