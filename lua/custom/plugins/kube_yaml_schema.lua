return {
  {
    dir = vim.fn.stdpath 'config',
    name = 'kube-yaml-schema.nvim',
    main = 'kube_yaml_schema',
    ft = {
      'yaml',
      'yaml.docker-compose',
      'yaml.gitlab',
      'yaml.helm-values',
    },
    cmd = {
      'KubeYamlSchemaRefresh',
      'KubeYamlSchemaRefreshAll',
      'KubeYamlSchemaContext',
      'KubeYamlSchemaClearCache',
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
