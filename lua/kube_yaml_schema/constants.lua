local M = {}

M.core_api_groups = {
  [''] = true,
  ['admissionregistration.k8s.io'] = true,
  ['apiextensions.k8s.io'] = true,
  ['apps'] = true,
  ['autoscaling'] = true,
  ['batch'] = true,
  ['certificates.k8s.io'] = true,
  ['coordination.k8s.io'] = true,
  ['discovery.k8s.io'] = true,
  ['events.k8s.io'] = true,
  ['flowcontrol.apiserver.k8s.io'] = true,
  ['networking.k8s.io'] = true,
  ['node.k8s.io'] = true,
  ['policy'] = true,
  ['rbac.authorization.k8s.io'] = true,
  ['scheduling.k8s.io'] = true,
  ['storage.k8s.io'] = true,
}

M.defaults = {
  kubectl_bin = 'kubectl',
  kubectl_timeout_ms = 5000,
  cache_ttl_seconds = 300,
  context_cache_ttl_seconds = 10,
  cache_dir = vim.fn.stdpath('cache') .. '/kube-yaml-schema',
  schema_store_url = 'https://www.schemastore.org/api/json/catalog.json',
  notify = true,
}

return M
