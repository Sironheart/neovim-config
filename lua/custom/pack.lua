-- vim.pack bootstrap: install/register plugins, load eager ones now, defer the rest.
-- Docs: :h vim.pack  |  lockfile: nvim-pack-lock.json (keep in git)

--- Expand `user/repo` (or Spec with `.src = 'user/repo'`) to a GitHub clone URL.
local function gh(spec)
  if type(spec) == 'string' then
    return 'https://github.com/' .. spec
  end
  return vim.tbl_extend('force', spec, { src = 'https://github.com/' .. spec.src })
end

-- Local plugin: vim.pack only manages Git remotes, so put it on rtp by hand.
local kube_yaml_schema = vim.fs.normalize '~/projects/forgejo.siron.casa/sironheart/kube_yaml_schema.nvim'
vim.opt.rtp:prepend(kube_yaml_schema)

-- Build blink after install/update (needs blink.lib on rtp first).
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'blink.cmp' and (kind == 'install' or kind == 'update') then
      vim.cmd.packadd 'blink.lib'
      if not ev.data.active then
        vim.cmd.packadd 'blink.cmp'
      end
      require('blink.cmp').build():pwait()
    end
  end,
})

-- Custom load=false-after-startup: skip :packadd so plugin/ scripts stay dormant until we ask.
-- (Default load=false during init.lua still sources plugin/ at startup step 11.)
local function defer_load() end

local function packadd_all(names)
  for _, name in ipairs(names) do
    vim.cmd.packadd(name)
  end
end

local function once(events, opts, callback)
  opts = opts or {}
  vim.api.nvim_create_autocmd(events, {
    group = vim.api.nvim_create_augroup('custom.pack.lazy', { clear = false }),
    pattern = opts.pattern,
    once = true,
    callback = callback,
  })
end

---------------------------------------------------------------------------
-- Eager: UI + tiny always-on plugins (needed before first paint / config hooks)
---------------------------------------------------------------------------
vim.pack.add {
  gh { src = 'kepano/flexoki-neovim', name = 'flexoki' },
  gh { src = 'nvim-mini/mini.nvim', version = vim.version.range '*' },
  gh 'folke/snacks.nvim',
  gh 'nvim-lualine/lualine.nvim',
  -- config.lua calls into this on commentstring queries
  gh 'JoosepAlviste/nvim-ts-context-commentstring',
  -- ftdetect must run early or FileType never fires for these
  gh 'tpope/vim-sleuth',
  gh 'NoahTheDuke/vim-just',
}

require('ts_context_commentstring').setup { enable_autocmd = false }
require 'custom.plugins.mini'
require 'custom.plugins.folke.snacks'
require 'custom.plugins.statusline'

vim.cmd.colorscheme 'flexoki-dark'

---------------------------------------------------------------------------
-- Deferred install registry: on disk + lockfile, not on rtp until packadd
---------------------------------------------------------------------------
vim.pack.add({
  gh 'kylechui/nvim-surround',
  gh 'lewis6991/gitsigns.nvim',
  gh 'stevearc/oil.nvim',
  gh 'windwp/nvim-ts-autotag',
  gh 'folke/which-key.nvim',
  gh 'folke/todo-comments.nvim',
  gh 'nvim-lua/plenary.nvim',
  gh 'folke/trouble.nvim',
  gh 'folke/persistence.nvim',
  gh 'folke/lazydev.nvim',
  gh 'Bilal2453/luvit-meta',
  gh 'saecki/crates.nvim',
  gh 'junnplus/lsp-setup.nvim',
  gh 'neovim/nvim-lspconfig',
  gh 'williamboman/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  gh 'j-hui/fidget.nvim',
  gh 'stevearc/conform.nvim',
  gh 'saghen/blink.lib',
  gh 'saghen/blink.cmp',
  gh 'rafamadriz/friendly-snippets',
  gh 'b0o/schemastore.nvim',
}, { load = defer_load })

---------------------------------------------------------------------------
-- VimEnter ≈ former lazy.nvim VeryLazy
---------------------------------------------------------------------------
once('VimEnter', {}, function()
  packadd_all {
    'nvim-surround',
    'gitsigns.nvim',
    'oil.nvim',
    'nvim-ts-autotag',
    'which-key.nvim',
    'plenary.nvim',
    'todo-comments.nvim',
    -- keymaps must exist before first buffer; plugin still hooks BufReadPre itself
    'persistence.nvim',
  }
  require 'custom.plugins.basic'
  require 'custom.plugins.treesitter'
  require 'custom.plugins.folke.which-key'
  require 'custom.plugins.folke.todo-comments'
  require 'custom.plugins.folke.persistence'
end)

---------------------------------------------------------------------------
-- Buffer open: LSP / completion / format stack
---------------------------------------------------------------------------
once({ 'BufReadPre', 'BufNewFile' }, {}, function()
  packadd_all {
    'blink.lib',
    'blink.cmp',
    'friendly-snippets',
    'schemastore.nvim',
    'mason.nvim',
    'mason-lspconfig.nvim',
    'mason-tool-installer.nvim',
    'fidget.nvim',
    'nvim-lspconfig',
    'lsp-setup.nvim',
    'conform.nvim',
  }
  require 'custom.plugins.cmp'
  require 'custom.plugins.kube_yaml_schema'
  require 'custom.plugins.lsp'
end)

---------------------------------------------------------------------------
-- Filetype / path keyed loads
---------------------------------------------------------------------------
once('FileType', { pattern = 'lua' }, function()
  packadd_all { 'luvit-meta', 'lazydev.nvim' }
  require 'custom.plugins.folke.lazydev'
end)

once('BufReadPre', { pattern = 'Cargo.toml' }, function()
  vim.cmd.packadd 'crates.nvim'
  require 'custom.plugins.language-specific.rust'
end)

---------------------------------------------------------------------------
-- Key-triggered: avoid loading Trouble until first use
---------------------------------------------------------------------------
vim.keymap.set('n', '<leader>xx', function()
  vim.cmd.packadd 'trouble.nvim'
  require 'custom.plugins.folke.trouble'
  vim.cmd 'Trouble diagnostics toggle'
end, { desc = 'Diagnostics (Trouble)' })
