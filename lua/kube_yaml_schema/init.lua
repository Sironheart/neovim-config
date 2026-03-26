local M = {}

local core_api_groups = {
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

local defaults = {
  kubectl_bin = 'kubectl',
  kubectl_timeout_ms = 5000,
  cache_ttl_seconds = 300,
  context_cache_ttl_seconds = 10,
  cache_dir = vim.fn.stdpath('cache') .. '/kube-yaml-schema',
  schema_store_url = 'https://www.schemastore.org/api/json/catalog.json',
  notify = true,
}

local state = {
  initialized = false,
  opts = vim.deepcopy(defaults),
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

local function now()
  return os.time()
end

local function sanitize_filename(value)
  return (value or ''):gsub('[^%w%._%-]', '_')
end

local function path_join(...)
  return table.concat({ ... }, '/')
end

local function notify(level, message)
  if not state.opts.notify then
    return
  end

  vim.notify(message, level, { title = 'kube-yaml-schema' })
end

local function is_yaml_filetype(bufnr)
  local filetype = vim.bo[bufnr].filetype
  return filetype == 'yaml' or filetype:match('^yaml') ~= nil
end

local function ensure_parent_dir(path)
  local parent = vim.fn.fnamemodify(path, ':h')
  if vim.fn.isdirectory(parent) == 0 then
    vim.fn.mkdir(parent, 'p')
  end
end

local function read_json_file(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    return nil
  end

  local encoded = table.concat(lines, '\n')
  if encoded == '' then
    return nil
  end

  local decode_ok, decoded = pcall(vim.json.decode, encoded)
  if not decode_ok then
    return nil
  end

  return decoded
end

local function write_json_file(path, data)
  local ok, encoded = pcall(vim.json.encode, data)
  if not ok or not encoded then
    return false
  end

  ensure_parent_dir(path)
  local write_ok = pcall(vim.fn.writefile, { encoded }, path)
  return write_ok
end

local function stat_mtime(path)
  local stat = vim.uv.fs_stat(path)
  if not stat or not stat.mtime then
    return nil
  end

  return stat.mtime.sec
end

local function is_cache_fresh(path, ttl_seconds)
  if ttl_seconds == 0 then
    return vim.fn.filereadable(path) == 1
  end

  local mtime = stat_mtime(path)
  if not mtime then
    return false
  end

  return (now() - mtime) <= ttl_seconds
end

local function context_cache_dir(context)
  return path_join(state.opts.cache_dir, sanitize_filename(context))
end

local function context_version_cache_path(context)
  return path_join(context_cache_dir(context), 'server-version.json')
end

local function context_crd_cache_path(context)
  return path_join(context_cache_dir(context), 'crd-index.json')
end

local function context_schema_dir(context)
  return path_join(context_cache_dir(context), 'schemas')
end

local function schema_file_path(context, group, kind, version)
  local filename = string.format('%s__%s__%s.json', sanitize_filename(group), sanitize_filename(kind), sanitize_filename(version))
  return path_join(context_schema_dir(context), filename)
end

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

local function parse_value(raw)
  if not raw then
    return nil
  end

  local value = vim.trim(raw)
  value = value:gsub('%s+#.*$', '')
  value = vim.trim(value)

  if value == '' then
    return nil
  end

  if value:sub(1, 1) == '"' and value:sub(-1) == '"' then
    value = value:sub(2, -2)
  elseif value:sub(1, 1) == "'" and value:sub(-1) == "'" then
    value = value:sub(2, -2)
  end

  if value:find('{{', 1, true) then
    return nil
  end

  return value
end

local function parse_api_version(api_version)
  if not api_version or api_version == '' then
    return '', ''
  end

  local group, version = api_version:match('^([^/]+)/(.+)$')
  if group and version then
    return group, version
  end

  return '', api_version
end

local function parse_kubernetes_resources(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local resources = {}
  local current = {}

  local function flush_resource()
    if current.kind and current.api_version then
      local group, version = parse_api_version(current.api_version)
      table.insert(resources, {
        group = group,
        version = version,
        kind = current.kind,
        core = core_api_groups[group] == true,
      })
    end

    current = {}
  end

  for _, line in ipairs(lines) do
    if line:match('^%s*%-%-%-%s*$') then
      flush_resource()
    else
      local kind = parse_value(line:match('^%s*kind%s*:%s*(.-)%s*$'))
      if kind then
        current.kind = kind
      end

      local api_version = parse_value(line:match('^%s*apiVersion%s*:%s*(.-)%s*$'))
      if api_version then
        current.api_version = api_version
      end
    end
  end

  flush_resource()

  return resources
end

local function parse_server_version(output)
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok or not decoded or not decoded.serverVersion then
    return nil
  end

  local git_version = decoded.serverVersion.gitVersion
  if type(git_version) ~= 'string' then
    return nil
  end

  local version = git_version:match('^v%d+%.%d+%.%d+')
  if version then
    return version
  end

  return git_version:sub(1, 1) == 'v' and git_version or 'v' .. git_version
end

local function normalize_schema(schema)
  if type(schema) ~= 'table' then
    return nil
  end

  local normalized = vim.deepcopy(schema)
  if normalized['$schema'] == nil then
    normalized['$schema'] = 'http://json-schema.org/draft-07/schema#'
  end

  return normalized
end

local function build_crd_index(crd_payload)
  local index = {
    by_key = {},
  }

  if type(crd_payload) ~= 'table' or type(crd_payload.items) ~= 'table' then
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

local function pick_crd_schema(entry, requested_version)
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

local function kubernetes_schema_uri(version)
  return string.format('https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/%s-standalone-strict/all.json', version)
end

local function get_current_context(callback)
  if state.context.value and state.context.expires_at > now() then
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
    state.context.expires_at = now() + state.opts.context_cache_ttl_seconds
    callback(context, nil)
  end)
end

local function flush_inflight(waiters, payload, err)
  for _, waiter in ipairs(waiters) do
    waiter(payload, err)
  end
end

local function get_server_version(context, callback)
  local cache = state.version_cache[context]
  if cache and cache.expires_at > now() then
    callback(cache.version, nil)
    return
  end

  local cache_path = context_version_cache_path(context)
  local stale = read_json_file(cache_path)
  if stale and is_cache_fresh(cache_path, state.opts.cache_ttl_seconds) then
    local version = stale.version
    if type(version) == 'string' and version ~= '' then
      local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (now() + state.opts.cache_ttl_seconds)
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
        local expires_at = now() + 60
        state.version_cache[context] = {
          version = stale.version,
          expires_at = expires_at,
        }
        flush_inflight(waiters, stale.version, nil)
        return
      end

      flush_inflight(waiters, nil, vim.trim(result.stderr or 'failed to fetch kubernetes version'))
      return
    end

    local version = parse_server_version(result.stdout or '')
    if not version then
      flush_inflight(waiters, nil, 'failed to parse kubernetes server version')
      return
    end

    local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (now() + state.opts.cache_ttl_seconds)
    state.version_cache[context] = {
      version = version,
      expires_at = expires_at,
    }

    write_json_file(cache_path, { version = version })
    flush_inflight(waiters, version, nil)
  end)
end

local function get_crd_index(context, callback)
  local cache = state.crd_cache[context]
  if cache and cache.expires_at > now() then
    callback(cache.index, nil)
    return
  end

  local cache_path = context_crd_cache_path(context)
  local stale = read_json_file(cache_path)
  if stale and is_cache_fresh(cache_path, state.opts.cache_ttl_seconds) then
    local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (now() + state.opts.cache_ttl_seconds)
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
        local expires_at = now() + 60
        state.crd_cache[context] = {
          index = stale,
          expires_at = expires_at,
        }
        flush_inflight(waiters, stale, nil)
        return
      end

      flush_inflight(waiters, nil, vim.trim(result.stderr or 'failed to fetch cluster CRDs'))
      return
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout or '')
    if not ok then
      flush_inflight(waiters, nil, 'failed to parse CRD list from kubectl')
      return
    end

    local index = build_crd_index(decoded)
    local expires_at = state.opts.cache_ttl_seconds == 0 and math.huge or (now() + state.opts.cache_ttl_seconds)
    state.crd_cache[context] = {
      index = index,
      expires_at = expires_at,
    }

    write_json_file(cache_path, index)
    flush_inflight(waiters, index, nil)
  end)
end

local function persist_schema(context, group, kind, version, schema)
  local normalized = normalize_schema(schema)
  if not normalized then
    return nil
  end

  local path = schema_file_path(context, group, kind, version)
  if not write_json_file(path, normalized) then
    return nil
  end

  return 'file://' .. path
end

local function merge_schema_overrides(client)
  local client_state = state.client_states[client.id]
  if not client_state then
    return
  end

  local merged = vim.deepcopy(client_state.base_schemas)

  for bufnr, override in pairs(client_state.overrides) do
    if vim.api.nvim_buf_is_valid(bufnr) and override and override.uri then
      merged[override.uri] = vim.uri_from_bufnr(bufnr)
    else
      client_state.overrides[bufnr] = nil
    end
  end

  local encoded = vim.json.encode(merged)
  if encoded == client_state.last_applied then
    return
  end

  local settings = vim.tbl_deep_extend('force', vim.deepcopy(client.settings or {}), {
    yaml = {
      schemas = merged,
    },
  })

  client.settings = settings
  client_state.last_applied = encoded
  client:notify('workspace/didChangeConfiguration', { settings = settings })
end

local function normalize_base_schemas(client)
  local schemas = ((client.settings or {}).yaml or {}).schemas

  if type(schemas) ~= 'table' or vim.tbl_islist(schemas) then
    return {}
  end

  return vim.deepcopy(schemas)
end

local function ensure_client_state(client)
  if state.client_states[client.id] then
    return state.client_states[client.id]
  end

  state.client_states[client.id] = {
    base_schemas = normalize_base_schemas(client),
    overrides = {},
    last_applied = nil,
  }

  return state.client_states[client.id]
end

local function remove_buffer_overrides(bufnr)
  for client_id, client_state in pairs(state.client_states) do
    if client_state.overrides[bufnr] ~= nil then
      client_state.overrides[bufnr] = nil
      local client = vim.lsp.get_client_by_id(client_id)
      if client and client.name == 'yamlls' then
        merge_schema_overrides(client)
      end
    end
  end
end

local function select_resource_schema(resources, callback)
  local non_core = {}

  for _, resource in ipairs(resources) do
    if not resource.core then
      table.insert(non_core, resource)
    end
  end

  get_current_context(function(context, context_err)
    if not context then
      callback(nil, context_err)
      return
    end

    if #non_core == 0 then
      get_server_version(context, function(version, version_err)
        if not version then
          callback(nil, version_err)
          return
        end

        callback({
          name = 'Kubernetes ' .. version,
          uri = kubernetes_schema_uri(version),
        }, nil)
      end)
      return
    end

    local unique_non_core = {}
    for _, resource in ipairs(non_core) do
      local key = string.lower(resource.group .. '|' .. resource.kind)
      unique_non_core[key] = resource
    end

    local candidates = vim.tbl_values(unique_non_core)
    if #candidates ~= 1 then
      callback(nil, nil)
      return
    end

    local selected = candidates[1]
    local key = string.lower(selected.group .. '|' .. selected.kind)

    get_crd_index(context, function(index, crd_err)
      if not index then
        callback(nil, crd_err)
        return
      end

      local entry = index.by_key and index.by_key[key] or nil
      if not entry then
        callback(nil, nil)
        return
      end

      local schema, version = pick_crd_schema(entry, selected.version)
      if not schema or not version then
        callback(nil, nil)
        return
      end

      local uri = persist_schema(context, entry.group, entry.kind, version, schema)
      if not uri then
        callback(nil, 'failed to persist CRD schema to cache')
        return
      end

      callback({
        name = string.format('%s %s/%s', entry.kind, entry.group, version),
        uri = uri,
      }, nil)
    end)
  end)
end

local function get_attached_yamlls_clients(bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr, name = 'yamlls' })
end

local function apply_buffer_schema(bufnr, schema)
  local clients = get_attached_yamlls_clients(bufnr)
  if #clients == 0 then
    return false
  end

  local changed = false

  for _, client in ipairs(clients) do
    local client_state = ensure_client_state(client)
    local current = client_state.overrides[bufnr]

    if schema and schema.uri then
      if not current or current.uri ~= schema.uri then
        client_state.overrides[bufnr] = {
          uri = schema.uri,
          name = schema.name,
        }
        changed = true
      end
    elseif current ~= nil then
      client_state.overrides[bufnr] = nil
      changed = true
    end

    if changed then
      merge_schema_overrides(client)
    end
  end

  return changed
end

local function refresh_buffer(bufnr, opts)
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local clients = get_attached_yamlls_clients(bufnr)
  if #clients == 0 then
    if opts.notify then
      notify(vim.log.levels.INFO, 'yamlls is not attached to this buffer')
    end
    return
  end

  local resources = parse_kubernetes_resources(bufnr)
  if #resources == 0 then
    local changed = apply_buffer_schema(bufnr, nil)
    if opts.notify then
      if changed then
        notify(vim.log.levels.INFO, 'Cleared Kubernetes schema override, using Schema Store fallback')
      else
        notify(vim.log.levels.INFO, 'No Kubernetes resource detected, using Schema Store fallback')
      end
    end
    return
  end

  state.refresh_tokens[bufnr] = (state.refresh_tokens[bufnr] or 0) + 1
  local token = state.refresh_tokens[bufnr]

  select_resource_schema(resources, function(schema, err)
    if state.refresh_tokens[bufnr] ~= token then
      return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    if err then
      local changed = apply_buffer_schema(bufnr, nil)
      if opts.notify then
        local message = changed and 'Failed to resolve Kubernetes schema, switched to Schema Store fallback' or 'Failed to resolve Kubernetes schema, using Schema Store fallback'
        notify(vim.log.levels.WARN, message .. ': ' .. err)
      end
      return
    end

    if not schema then
      local changed = apply_buffer_schema(bufnr, nil)
      if opts.notify then
        if changed then
          notify(vim.log.levels.INFO, 'No applicable cluster schema found, switched to Schema Store fallback')
        else
          notify(vim.log.levels.INFO, 'No applicable cluster schema found, using Schema Store fallback')
        end
      end
      return
    end

    local changed = apply_buffer_schema(bufnr, schema)
    if opts.notify then
      local action = changed and 'Applied' or 'Kept'
      notify(vim.log.levels.INFO, string.format('%s schema override: %s', action, schema.name))
    end
  end)
end

local function clear_cache()
  state.context = { value = nil, expires_at = 0 }
  state.version_cache = {}
  state.version_inflight = {}
  state.crd_cache = {}
  state.crd_inflight = {}

  if vim.fn.isdirectory(state.opts.cache_dir) == 1 then
    vim.fn.delete(state.opts.cache_dir, 'rf')
  end
end

function M.yamlls_config(extra)
  local config = {
    settings = {
      redhat = {
        telemetry = {
          enabled = false,
        },
      },
      yaml = {
        validate = true,
        format = {
          enable = true,
        },
        hover = true,
        schemaStore = {
          enable = true,
          url = (state.opts or defaults).schema_store_url,
        },
        schemaDownload = {
          enable = true,
        },
        schemas = {},
      },
    },
  }

  if extra then
    return vim.tbl_deep_extend('force', config, extra)
  end

  return config
end

function M.setup(opts)
  state.opts = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})

  if state.initialized then
    return
  end

  state.initialized = true

  local group = vim.api.nvim_create_augroup('kube-yaml-schema', { clear = true })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= 'yamlls' then
        return
      end

      ensure_client_state(client)
      refresh_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
    group = group,
    callback = function(args)
      if not is_yaml_filetype(args.buf) then
        return
      end

      refresh_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(args)
      remove_buffer_overrides(args.buf)
      state.refresh_tokens[args.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command('KubeYamlSchemaRefresh', function()
    refresh_buffer(vim.api.nvim_get_current_buf(), { notify = true })
  end, {
    desc = 'Refresh Kubernetes YAML schema override for current buffer',
  })

  vim.api.nvim_create_user_command('KubeYamlSchemaClearCache', function()
    clear_cache()
    notify(vim.log.levels.INFO, 'Cleared kube-yaml-schema cache')
    refresh_buffer(vim.api.nvim_get_current_buf(), { notify = true })
  end, {
    desc = 'Clear kube-yaml-schema cache',
  })
end

return M
