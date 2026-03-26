local cache = require 'kube_yaml_schema.cache'
local constants = require 'kube_yaml_schema.constants'
local kubectl = require 'kube_yaml_schema.kubectl'
local lsp = require 'kube_yaml_schema.lsp'
local resolver = require 'kube_yaml_schema.resolver'
local state = require 'kube_yaml_schema.state'
local util = require 'kube_yaml_schema.util'

local M = {}

local function fallback_message(changed, base)
  if changed then
    return base .. ', switched to Schema Store fallback'
  end

  return base .. ', using Schema Store fallback'
end

local function notify_resolution_result(opts, result, err, changed)
  if not opts.notify then
    return
  end

  if err then
    util.notify(vim.log.levels.WARN, fallback_message(changed, 'Failed to resolve Kubernetes schema') .. ': ' .. err)
    return
  end

  local schema = result and result.schema or nil
  if schema then
    local action = changed and 'Applied' or 'Kept'
    util.notify(vim.log.levels.INFO, string.format('%s schema override: %s', action, schema.name))
    return
  end

  local reason = result and result.reason or 'no-cluster-schema'
  if reason == 'no-kubernetes-resource' then
    local message = changed and 'Cleared Kubernetes schema override' or 'No Kubernetes resource detected'
    util.notify(vim.log.levels.INFO, message .. ', using Schema Store fallback')
    return
  end

  if reason == 'ambiguous-crd' then
    util.notify(vim.log.levels.INFO, fallback_message(changed, 'Multiple CRD kinds detected'))
    return
  end

  util.notify(vim.log.levels.INFO, fallback_message(changed, 'No applicable cluster schema found'))
end

local function refresh_buffer(bufnr, opts)
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local clients = lsp.attached_yamlls_clients(bufnr)
  if #clients == 0 then
    if opts.notify then
      util.notify(vim.log.levels.INFO, 'yamlls is not attached to this buffer')
    end
    return
  end

  state.refresh_tokens[bufnr] = (state.refresh_tokens[bufnr] or 0) + 1
  local token = state.refresh_tokens[bufnr]

  resolver.resolve_for_buffer(bufnr, function(result, err)
    if state.refresh_tokens[bufnr] ~= token then
      return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    local schema = result and result.schema or nil
    local changed = lsp.apply_buffer_schema(bufnr, schema)
    notify_resolution_result(opts, result, err, changed)
  end)
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
          url = state.opts.schema_store_url,
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
  state.opts = vim.tbl_deep_extend('force', vim.deepcopy(constants.defaults), opts or {})

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

      lsp.ensure_client_state(client)
      refresh_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = group,
    callback = function(args)
      if args.data and args.data.client_id then
        lsp.remove_client_state(args.data.client_id)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
    group = group,
    callback = function(args)
      if util.is_yaml_filetype(args.buf) then
        refresh_buffer(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(args)
      lsp.remove_buffer_overrides(args.buf)
      state.refresh_tokens[args.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command('KubeYamlSchemaRefresh', function()
    refresh_buffer(vim.api.nvim_get_current_buf(), { notify = true })
  end, {
    desc = 'Refresh Kubernetes YAML schema override for current buffer',
  })

  vim.api.nvim_create_user_command('KubeYamlSchemaClearCache', function()
    kubectl.clear_runtime_cache()
    cache.clear_all_files()
    util.notify(vim.log.levels.INFO, 'Cleared kube-yaml-schema cache')
    refresh_buffer(vim.api.nvim_get_current_buf(), { notify = true })
  end, {
    desc = 'Clear kube-yaml-schema cache',
  })
end

return M
