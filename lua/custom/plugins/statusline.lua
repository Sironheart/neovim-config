return {
  'nvim-lualine/lualine.nvim',
  opts = {
    options = {
      theme = 'papercolor_dark',
    },
    sections = {
      -- lualine_w = { 'encoding', 'fileformat', 'filetype' },
      lualine_c = { { 'filename', path = 3 } },
      lualine_y = { 'lsp_status' },
    },
  },
}
