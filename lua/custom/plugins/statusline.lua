-- Eager: statusline

require('lualine').setup {
  options = {
    theme = 'papercolor_dark',
  },
  sections = {
    lualine_c = { { 'filename', path = 3 } },
    lualine_y = { 'lsp_status' },
  },
}
