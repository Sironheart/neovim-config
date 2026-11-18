-- Count pending vim.pack updates without touching plugin repos: `git ls-remote` only reads the remote,
-- unlike vim.pack.update() which fetches and always opens its confirmation buffer.

--- Map ref name -> commit sha. Annotated tags list a peeled `<tag>^{}` line (the commit)
--- right after the tag object line, so it overwrites it.
local function parse_refs(stdout)
  local refs = {}
  for sha, ref in stdout:gmatch '(%x+)\t(%S+)' do
    refs[ref:gsub('%^{}$', '')] = sha
  end
  return refs
end

--- Commit vim.pack would update to. Nil for pinned commits (never a remote ref).
local function target_sha(version, refs)
  if version == nil then
    return refs.HEAD
  end
  if type(version) == 'string' then
    return refs['refs/tags/' .. version] or refs['refs/heads/' .. version]
  end
  local best_version, best_sha
  for ref, sha in pairs(refs) do
    local tag = ref:match '^refs/tags/(.+)'
    local v = tag and vim.version.parse(tag, { strict = false })
    if v and version:has(v) and (not best_version or v > best_version) then
      best_version, best_sha = v, sha
    end
  end
  return best_sha
end

local function check()
  local plugs = vim.pack.get(nil, { info = false })
  local pending, count = #plugs, 0
  for _, p in ipairs(plugs) do
    vim.system({ 'git', 'ls-remote', 'origin' }, { cwd = p.path, text = true }, function(res)
      local sha = res.code == 0 and target_sha(p.spec.version, parse_refs(res.stdout))
      if sha and sha ~= p.rev then
        count = count + 1
      end
      pending = pending - 1
      if pending == 0 then
        local msg = 'vim.pack: all plugins up to date'
        if count > 0 then
          msg = ('vim.pack: %d update(s) available, run :lua vim.pack.update()'):format(count)
        end
        vim.schedule(function()
          vim.notify(msg)
        end)
      end
    end)
  end
end

vim.api.nvim_create_user_command('PackCheck', check, { desc = 'Check for vim.pack updates' })

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('custom.pack.check', {}),
  once = true,
  callback = check,
})
