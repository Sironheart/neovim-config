-- BufReadPre with LSP: local kube schema helper for yamlls

require('kube_yaml_schema').setup {
  auto_refresh = true,
  cache_ttl_seconds = 300,
  notify = true,
  notify_on_auto_refresh = false,
  refresh_on_kubernetes_fields = true,
  stale_on_error_seconds = 60,
}
