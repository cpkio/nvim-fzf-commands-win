local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)

  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = (term.fzf_colors .. '--header-lines=0 --prompt="File Types> "')

    local line = options.fzf(vim.fn.getcompletion('','filetype'), opts)
    if not line then
      return
    end

    api.command('set ft='.. line[1])

  end)()
end

