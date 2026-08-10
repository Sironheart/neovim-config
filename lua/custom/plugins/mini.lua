-- Eager: mini modules used for basics / oil icons

require('mini.icons').setup()

require('mini.basics').setup {
  mappings = {
    basic = true,
    windows = true,
    move_with_alt = true,
  },
}
require('mini.ai').setup { n_lines = 500 }
require('mini.move').setup()
require('mini.trailspace').setup()
