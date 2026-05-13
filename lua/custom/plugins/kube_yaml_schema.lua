return {
  {
    'sironheart/kube_yaml_schema.nvim',
    dir = vim.fs.normalize '~/projects/forgejo.siron.casa/sironheart/kube_yaml_schema.nvim',
    dependencies = {
      'b0o/schemastore.nvim',
    },
    opts = {
      auto_refresh = true,
      cache_ttl_seconds = 300,
      notify = true,
      notify_on_auto_refresh = false,
      refresh_on_kubernetes_fields = true,
      stale_on_error_seconds = 60,
    },
  },
}
