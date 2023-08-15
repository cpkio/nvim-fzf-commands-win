local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local utf = require "lua-utf8"
local fn, api = utils.helpers()

return function(options)
  options = utils.normalize_opts(options)
  local opts = (term.fzf_colors .. '--delimiter="'..utils.delim..'" --nth=2 --expect=ctrl-q --ansi --multi --prompt="History> "')
  local command_history = vim.fn.execute("history:")
  command_history = vim.split(command_history, "\n")

  coroutine.wrap(function()
    local items = {}

    for i = #command_history, 3, -1 do
      local item = command_history[i]
      local index, text = string.match(item, "(%d+) +(.+)")
      local line = string.format("%-20s", term.green .. index .. term.reset) ..
                   utils.delim ..
                   text
      table.insert(items, line)
    end

    local lines = options.fzf(items, opts)

    if not lines then return end

    if lines[1] == "" then
      for i = 2, #lines do
        local cmd = utf.match(lines[i], ".+"..utils.delim.."(.+)")
        vim.fn.execute(cmd)
      end
    end

    if lines[1] == "ctrl-q" then
      for i = 2, #lines do
        local index = utf.match(lines[i], "(%d+) +")
        local res = fn.histdel(':', tonumber(index))
      end
      api.command('wshada!')
    end

  end)()
end
