local constants = require 'kube_yaml_schema.constants'

local M = {
  initialized = false,
  opts = vim.deepcopy(constants.defaults),
  context = {
    value = nil,
    expires_at = 0,
  },
  version_cache = {},
  version_inflight = {},
  crd_cache = {},
  crd_inflight = {},
  refresh_tokens = {},
  client_states = {},
}

function M.reset_runtime()
  M.context = {
    value = nil,
    expires_at = 0,
  }
  M.version_cache = {}
  M.version_inflight = {}
  M.crd_cache = {}
  M.crd_inflight = {}
  M.refresh_tokens = {}
end

return M
