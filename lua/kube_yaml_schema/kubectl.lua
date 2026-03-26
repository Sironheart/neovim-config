local cache = require 'kube_yaml_schema.cache'
local state = require 'kube_yaml_schema.state'
local util = require 'kube_yaml_schema.util'

local M = {}

local function run_kubectl(args, callback)
  local command = { state.opts.kubectl_bin }
  vim.list_extend(command, args)

  vim.system(command, { text = true, timeout = state.opts.kubectl_timeout_ms }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

local function run_kubectl_for_context(context, args, callback)
  local full_args = { '--context', context }
  vim.list_extend(full_args, args)
  run_kubectl(full_args, callback)
end

local function flush_waiters(waiters, payload, err)
  for _, waiter in ipairs(waiters) do
    waiter(payload, err)
  end
end

local function parse_server_version(output)
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok or type(decoded) ~= 'table' or type(decoded.serverVersion) ~= 'table' then
    return nil
  end

  local git_version = decoded.serverVersion.gitVersion
  if type(git_version) ~= 'string' then
    return nil
  end

  local version = git_version:match '^v%d+%.%d+%.%d+'
  if version then
    return version
  end

  if git_version:sub(1, 1) == 'v' then
    return git_version
  end

  return 'v' .. git_version
end

local function build_crd_index(crd_payload)
  local index = {
    by_key = {},
  }

  if type(crd_payload) ~= 'table' or not vim.islist(crd_payload.items) then
    return index
  end

  for _, item in ipairs(crd_payload.items) do
    local spec = item.spec or {}
    local names = spec.names or {}
    local group = spec.group
    local kind = names.kind

    if type(group) == 'string' and group ~= '' and type(kind) == 'string' and kind ~= '' then
      local versions = {}
      local version_order = {}

      for _, version in ipairs(spec.versions or {}) do
        if type(version) == 'table' and type(version.name) == 'string' then
          versions[version.name] = {
            name = version.name,
            served = version.served == true,
            storage = version.storage == true,
            schema = version.schema and version.schema.openAPIV3Schema or nil,
          }
          table.insert(version_order, version.name)
        end
      end

      local key = string.lower(group .. '|' .. kind)
      index.by_key[key] = {
        group = group,
        kind = kind,
        name = item.metadata and item.metadata.name or nil,
        versions = versions,
        version_order = version_order,
      }
    end
  end

  return index
end

function M.pick_crd_schema(entry, requested_version)
  if not entry then
    return nil, nil
  end

  local versions = entry.versions or {}
  local version_order = entry.version_order or {}

  if requested_version and versions[requested_version] and versions[requested_version].schema then
    return versions[requested_version].schema, requested_version
  end

  for _, version_name in ipairs(version_order) do
    local candidate = versions[version_name]
    if candidate and candidate.storage and candidate.schema then
      return candidate.schema, version_name
    end
  end

  for _, version_name in ipairs(version_order) do
    local candidate = versions[version_name]
    if candidate and candidate.served and candidate.schema then
      return candidate.schema, version_name
    end
  end

  for _, version_name in ipairs(version_order) do
    local candidate = versions[version_name]
    if candidate and candidate.schema then
      return candidate.schema, version_name
    end
  end

  return nil, nil
end

function M.get_current_context(callback)
  if state.context.value and state.context.expires_at > util.now() then
    callback(state.context.value, nil)
    return
  end

  run_kubectl({ 'config', 'current-context' }, function(result)
    if result.code ~= 0 then
      callback(nil, vim.trim(result.stderr or 'unable to resolve current kubectl context'))
      return
    end

    local context = vim.trim(result.stdout or '')
    if context == '' then
      callback(nil, 'kubectl current-context returned an empty value')
      return
    end

    state.context.value = context
    state.context.expires_at = util.now() + state.opts.context_cache_ttl_seconds
    callback(context, nil)
  end)
end

function M.get_server_version(context, callback)
  local cached = state.version_cache[context]
  if cached and cached.expires_at > util.now() then
    callback(cached.version, nil)
    return
  end

  local cache_path = cache.context_version_cache_path(context)
  local stale = cache.read_json_file(cache_path)

  if stale and cache.is_cache_fresh(cache_path, state.opts.cache_ttl_seconds) then
    local version = stale.version
    if type(version) == 'string' and version ~= '' then
      local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (util.now() + state.opts.cache_ttl_seconds)
      state.version_cache[context] = {
        version = version,
        expires_at = expires_at,
      }
      callback(version, nil)
      return
    end
  end

  if state.version_inflight[context] then
    table.insert(state.version_inflight[context], callback)
    return
  end

  state.version_inflight[context] = { callback }

  run_kubectl_for_context(context, { 'version', '--output=json' }, function(result)
    local waiters = state.version_inflight[context]
    state.version_inflight[context] = nil

    if result.code ~= 0 then
      if stale and type(stale.version) == 'string' and stale.version ~= '' then
        state.version_cache[context] = {
          version = stale.version,
          expires_at = util.now() + 60,
        }
        flush_waiters(waiters, stale.version, nil)
        return
      end

      flush_waiters(waiters, nil, vim.trim(result.stderr or 'failed to fetch kubernetes version'))
      return
    end

    local version = parse_server_version(result.stdout or '')
    if not version then
      flush_waiters(waiters, nil, 'failed to parse kubernetes server version')
      return
    end

    local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (util.now() + state.opts.cache_ttl_seconds)
    state.version_cache[context] = {
      version = version,
      expires_at = expires_at,
    }

    cache.write_json_file(cache_path, { version = version })
    flush_waiters(waiters, version, nil)
  end)
end

function M.get_crd_index(context, callback)
  local cached = state.crd_cache[context]
  if cached and cached.expires_at > util.now() then
    callback(cached.index, nil)
    return
  end

  local cache_path = cache.context_crd_cache_path(context)
  local stale = cache.read_json_file(cache_path)

  if stale and cache.is_cache_fresh(cache_path, state.opts.cache_ttl_seconds) then
    local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (util.now() + state.opts.cache_ttl_seconds)
    state.crd_cache[context] = {
      index = stale,
      expires_at = expires_at,
    }
    callback(stale, nil)
    return
  end

  if state.crd_inflight[context] then
    table.insert(state.crd_inflight[context], callback)
    return
  end

  state.crd_inflight[context] = { callback }

  run_kubectl_for_context(context, { 'get', 'crd', '--output=json' }, function(result)
    local waiters = state.crd_inflight[context]
    state.crd_inflight[context] = nil

    if result.code ~= 0 then
      if stale then
        state.crd_cache[context] = {
          index = stale,
          expires_at = util.now() + 60,
        }
        flush_waiters(waiters, stale, nil)
        return
      end

      flush_waiters(waiters, nil, vim.trim(result.stderr or 'failed to fetch cluster CRDs'))
      return
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout or '')
    if not ok then
      flush_waiters(waiters, nil, 'failed to parse CRD list from kubectl')
      return
    end

    local index = build_crd_index(decoded)
    local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (util.now() + state.opts.cache_ttl_seconds)

    state.crd_cache[context] = {
      index = index,
      expires_at = expires_at,
    }

    cache.write_json_file(cache_path, index)
    flush_waiters(waiters, index, nil)
  end)
end

function M.clear_runtime_cache()
  state.reset_runtime()
end

return M
