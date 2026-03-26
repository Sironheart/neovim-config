local cache = require 'kube_yaml_schema.cache'
local kubectl = require 'kube_yaml_schema.kubectl'
local parser = require 'kube_yaml_schema.parser'

local M = {}

local function kubernetes_schema_uri(version)
  return string.format(
    'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/all.json',
    version
  )
end

local function dedupe_non_core_resources(resources)
  local unique = {}

  for _, resource in ipairs(resources) do
    if not resource.core then
      local key = string.lower(resource.group .. '|' .. resource.kind)
      unique[key] = resource
    end
  end

  return vim.tbl_values(unique)
end

function M.resolve_for_buffer(bufnr, callback)
  local resources = parser.parse_kubernetes_resources(bufnr)
  if #resources == 0 then
    callback({ reason = 'no-kubernetes-resource' }, nil)
    return
  end

  kubectl.get_current_context(function(context, context_err)
    if not context then
      callback({ reason = 'context-unavailable' }, context_err)
      return
    end

    local non_core = dedupe_non_core_resources(resources)
    if #non_core == 0 then
      kubectl.get_server_version(context, function(version, version_err)
        if not version then
          callback({ reason = 'core-version-unavailable' }, version_err)
          return
        end

        callback({
          reason = 'core-resource',
          schema = {
            name = 'Kubernetes ' .. version,
            uri = kubernetes_schema_uri(version),
          },
        }, nil)
      end)
      return
    end

    if #non_core ~= 1 then
      callback({ reason = 'ambiguous-crd' }, nil)
      return
    end

    local selected = non_core[1]
    local key = string.lower(selected.group .. '|' .. selected.kind)

    kubectl.get_crd_index(context, function(index, crd_err)
      if not index then
        callback({ reason = 'crd-index-unavailable' }, crd_err)
        return
      end

      local entry = index.by_key and index.by_key[key] or nil
      if not entry then
        callback({ reason = 'no-cluster-schema' }, nil)
        return
      end

      local schema_body, schema_version = kubectl.pick_crd_schema(entry, selected.version)
      if not schema_body or not schema_version then
        callback({ reason = 'no-cluster-schema' }, nil)
        return
      end

      local uri = cache.persist_schema(context, entry.group, entry.kind, schema_version, schema_body)
      if not uri then
        callback({ reason = 'cache-write-failed' }, 'failed to persist CRD schema to cache')
        return
      end

      callback({
        reason = 'cluster-crd',
        schema = {
          name = string.format('%s %s/%s', entry.kind, entry.group, schema_version),
          uri = uri,
        },
      }, nil)
    end)
  end)
end

return M
