local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(opts)

  opts = utils.normalize_opts(opts)
  local command
  if fn.executable("fd") == 1 then
    command = 'fd --no-ignore --color=never --type=directory -d 8 --base-directory="..\\..\\..\\.."'
  end

  coroutine.wrap(function ()
    local choice = opts.fzf(command,
      (term.fzf_colors .. '--expect=ctrl-g,ctrl-l --prompt="Folder> "'))

    if not choice then return end

    local vimcmd
    if choice[1] == "ctrl-g" then
      vimcmd = "cd"
    elseif choice[1] == "ctrl-l" then
      vimcmd = "lcd"
    else
      vimcmd = "tcd"
    end

    vim.cmd(vimcmd .. " " .. fn.fnameescape('..\\..\\..\\..\\' .. choice[2]))

  end)()
end

