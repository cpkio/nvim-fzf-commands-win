local utf = require'lua-utf8'
local M = {}

M.delim = ' '

M.api = {
  __index = function(self, item)
    self[item] = vim.api["nvim_" .. item]
    return self[item]
  end
}

setmetatable(M.api, M.api)

M.fn = vim.fn

function M.helpers()
  return M.fn, M.api
end

function M.normalize_opts(opts)
  if not opts then opts = {} end
  if not opts.fzf then opts.fzf = require"fzf".fzf end
  return opts
end

function M.unnil(c)
  if not c or c == vim.NIL then
    return '‧'
  end
  return c
end

function M.pad(content, len)
  local content = M.unnil(content)
  local pad = len - utf.len(content)
  if pad <= 0 then return content end
  local pre = pad / 2
  local post = pad / 2 + pad % 2
  return string.rep(' ', pre) .. content .. string.rep(' ', post)
end

return M
