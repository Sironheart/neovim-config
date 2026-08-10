-- BufReadPre Cargo.toml: crates.io completion / LSP

require('crates').setup {
  lsp = {
    enabled = true,
    actions = true,
    completion = true,
    hover = true,
  },
}
