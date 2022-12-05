local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

local rg_delimiter=' ' -- 0x202F
-- local rg_delimiter=' '

return function(options)

  -- port from fzf.vim
  local function locate(bufnum)
    for tab = 1, vim.fn.tabpagenr('$') do
      local buffers = vim.fn.tabpagebuflist(tab)
      for k, buf in pairs(buffers) do
        if bufnum == buf then
          return tab, k
        end
      end
    end
    return 0, 0
  end

  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = ('--reverse --header-lines=1 --multi --ansi --prompt="Lines> "')
    local items = {}

    -- Loading buffers list
    local reglist = ('%s'):format(api.exec('buffers', { output = true }))

    for line in reglist:gmatch('([^\n]*)\n?') do
      -- Parsing active buffers list
      local bufnum, status, _, filepath, _ = string.match(line, '^%s*(%d+)%s+(%p?)(%w)%s+"([^"]+)"%s*line%s*(%d+)')
      if bufnum then
        -- reg = string.gsub(reg, [[\(.)]], '%1') -- Unescape
        -- regdata = string.gsub(regdata, [[\(.)]], '%1') -- Unescape
        if filepath == "" then
          filepath = "[No name]"
        end

        -- Get buffer lines for each found buffer
        local buflines = api.buf_get_lines(tonumber(bufnum),0,-1,0)

        for linenum, line in pairs(buflines) do
          if #line > 0 then
            line = string.format("%-18s", term.red .. tostring(bufnum) .. term.reset) ..
                   rg_delimiter ..
                   string.format("%-18s", term.green .. tostring(filepath) .. term.reset) ..
                   rg_delimiter ..
                   string.format("%-18s", term.blue .. tostring(linenum) .. term.reset) ..
                   rg_delimiter ..
                   line
            table.insert(items, line)
          end
        end
      end
    end

    local tip = term.green .. 'ENTER' .. term.reset .. ' to push to Quickfix list.'

    table.insert(items, 1, tip)

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    if #lines == 1 then
      local _b, _, _l = string.match(lines[1], '^%s*(%d+)%s*' .. rg_delimiter .. '([^' .. rg_delimiter .. ']+)'.. rg_delimiter .. '%s*(%d+)')
      local buf = tonumber(_b); local ln = tonumber(_l)
      local bufinfo = fn.getbufinfo(buf)[1]
      if bufinfo.hidden == 1 then
        api.win_set_buf(fn.win_getid(), buf)
        api.win_set_cursor(fn.win_getid(), { tonumber(ln), 0 })
      end
      if bufinfo.hidden == 0 then
        local _t, _w = locate(buf)
        api.command(_t .. 'tabnext')
        api.command(_w .. 'wincmd w')
        api.win_set_cursor(api.get_current_win(), { tonumber(_l), 0 })
      end
    else
      local itemsqf = {}
      for j = 1, #lines do
        local _b, _f, _l, _t = string.match(lines[j], '^%s*(%d+)%s*' .. rg_delimiter .. '([^' .. rg_delimiter .. ']+)'.. rg_delimiter .. '%s*(%d+)%s*' .. rg_delimiter .. '%s*(%S.+)')
        table.insert(itemsqf, { bufnr = tonumber(_b), filename = _f, lnum = tonumber(_l), text = _t})
      end
      fn.setqflist({},'r',{ id = 'FzfLines', items = itemsqf, title = 'FzfLines'})
      api.command('copen')
    end

  end)()
end

