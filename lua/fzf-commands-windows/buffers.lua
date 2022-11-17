local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)

  -- port from fzf.vim
  local function locate(bufnum)
    print(bufnum)
    for tab = 1, vim.fn.tabpagenr('$') do
      local buffers = vim.fn.tabpagebuflist(tab)
      for k, buf in pairs(buffers) do
        print(buf)
        if bufnum == buf then
          return tab, k
        end
      end
    end
    return 0, 0
  end

  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = ('--header-lines=2 --ansi --multi --expect=ctrl-q --prompt="Buffers> "')
    local items = {}

    local reglist = ('%s'):format(api.exec('buffers', { output = true }))

    for line in reglist:gmatch('([^\n]*)\n?') do
      local bufnum, status, active, filepath, linenum = string.match(line, '^%s*(%d+)%s+(%p?)(%w)%s+"([^"]+)"%s*line%s*(%d+)')
      if bufnum then
        -- reg = string.gsub(reg, [[\(.)]], '%1') -- Unescape
        -- regdata = string.gsub(regdata, [[\(.)]], '%1') -- Unescape
        local item_string = string.format("%-18s", term.red .. ' ' .. tostring(bufnum) .. ' ' .. term.reset) ..
                            string.format("%-20s", term.green .. ' ' .. tostring(status) .. ' ' .. term.reset) ..
                            filepath
        table.insert(items, item_string)
      end
    end

    local head = ' #    ?     file'
    local tip = term.green .. 'CTRL-Q' .. term.reset .. ' to delete buffer(s). '

    table.insert(items, 1, head)
    table.insert(items, 1, tip)

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    local cmd
    if lines[1] == "" then -- you can go only to one buffer on keypress
      local bufnum, _ = string.match(lines[2], '^%s*(%d+)')
      local t, w = locate(tonumber(bufnum))
      api.command(t .. 'tabnext')
      api.command(w .. 'wincmd w')
    elseif lines[1] == "ctrl-q" then
      for i = 2, #lines do
        local bufnum, _ = string.match(lines[i], '^%s*(%d+)')
        cmd = 'bdelete! ' .. bufnum
        api.command(cmd)
      end
    end
  end)()
end
