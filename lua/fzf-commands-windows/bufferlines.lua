local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)
  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = ('--reverse --header-lines=0 --multi --expect=alt-enter --ansi --prompt="BLines> "')
    local items = {}

    local buflines = api.buf_get_lines(0,0,-1,0)

    for i, line in pairs(buflines) do
      if #line > 0 then
        line = string.format("%-18s", term.red .. ' ' .. tostring(i) .. ' ' .. term.reset) .. line
        table.insert(items, line)
      end
    end

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    if lines[1] == "" then
      if #lines == 2 then
        local linenum, _ = string.match(lines[1], '^%s*(%d+)')
        api.command(linenum)
      else
        local bufnum = api.get_current_buf()
        local itemsqf = {}
        for j = 2, #lines do
          local linenum, line = string.match(lines[j], '^%s*(%d+)%s*(%S.+)')
          table.insert(itemsqf, { bufnr = bufnum, lnum = tonumber(linenum), text = line })
        end
        fn.setqflist({},'r',{ id = 'FzfBLines', items = itemsqf, title = 'FzfBLines'})
        api.command('copen')
      end
    end
    if lines[1] == "alt-enter" then
      if #lines == 2 then
        local linenum, _ = string.match(lines[1], '^%s*(%d+)')
        api.command(linenum)
      else
        local bufnum = api.get_current_buf()
        local itemsqf = {}
        for j = 2, #lines do
          local linenum, line = string.match(lines[j], '^%s*(%d+)%s*(%S.+)')
          table.insert(itemsqf, { bufnr = bufnum, lnum = tonumber(linenum), text = line })
        end
        fn.setloclist(fn.win_getid(),{},'r',{ id = 'FzfBLines', items = itemsqf, title = 'FzfBLines'})
        api.command('lopen')
      end
    end

  end)()
end
