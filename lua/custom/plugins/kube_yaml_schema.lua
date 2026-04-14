return {
  {
    'sironheart/kube_yaml_schema.nvim',
    dir = vim.fs.normalize '~/projects/github.com/sironheart/kube_yaml_schema.nvim',
    dependencies = {
      'b0o/schemastore.nvim',
    },
    opts = {
      auto_refresh = true,
      notify = true,
      notify_on_auto_refresh = false,
      cache_ttl_seconds = 300,
      stale_on_error_seconds = 60,
    },
  },
}
