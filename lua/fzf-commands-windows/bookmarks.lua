local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()
local marks = require'marks'

return function(options)
  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = (term.fzf_colors .. '--delimiter="' .. utils.delim .. '" --ansi --prompt="Bookmarks> "')
    local items = {}

    local ns = {}
    local spaces = api.get_namespaces()
    for i = 0,9 do
      local _ns = spaces['Bookmarks'..i]
      if _ns ~= nil then table.insert(ns, _ns) end
    end

    local bmks = {}
    for _, v in pairs(marks.bookmark_state.groups) do
      for _, w in pairs(v.marks) do
        for l, x in pairs(w) do
          x.sign = v.sign
          bmks[l] = x
        end
      end
    end

    local extmarks = {}
    local getmarks = api.buf_get_extmarks
    for _, u in pairs(ns) do
      for _, v in pairs(getmarks(0, u, 0, -1, { details = true})) do
        local _t = ''
        if v[4].virt_lines then _t = unpack(unpack(unpack(v[4].virt_lines))) end
        table.insert(extmarks, { v[2]+1, _t })
      end
    end
    table.sort(extmarks, function(a,b) return a[1] < b[1] end)

    local getlines = api.buf_get_lines
    for _, v in pairs(extmarks) do
      local sign = bmks[v[1]].sign
      table.insert(items,
        term.cyan .. sign .. term.reset ..
        utils.delim ..
        term.green .. string.format("%-6s", v[1]) .. term.reset ..
        utils.delim ..
        v[2] ..
        utils.delim ..
        term.brightcyan .. unpack(getlines(0, v[1]-1, v[1], false)) .. term.reset
      )
    end

    local bookmark = options.fzf(items, opts)
    if not bookmark then
      return
    end

    local line = string.match(bookmark[1], utils.delim..'(%d+)')
    api.command('normal ' .. line .. 'ggzz')
  end)()
end
