local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)
  options = utils.normalize_opts(options)
  local opts = (term.fzf_colors .. ' --ansi --prompt="History> "')
  local command_history = vim.fn.execute("history:")
  command_history = vim.split(command_history, "\n")

  coroutine.wrap(function()
    local items = {}

    for i = #command_history, 3, -1 do
      local item = command_history[i]
      local _, finish = string.find(item, "%d+ +")
      table.insert(items, string.sub(item, finish + 1))
    end

    local line = options.fzf(items, opts)
    if not line then
      return
    end

    vim.fn.execute(line)

  end)()
end
