local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)
  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = ('--header-lines=0 --ansi --prompt="BLines> "')
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

    local cmd
    local linenum, _ = string.match(lines[1], '^%s*(%d+)')
    print(linenum)
    api.command(tostring(linenum))

-- TODO
-- 3) pass multiple lines to quickfix list

  end)()
end
