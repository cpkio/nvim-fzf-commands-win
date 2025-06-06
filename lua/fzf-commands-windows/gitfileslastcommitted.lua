local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"

local fn, api = utils.helpers()

return function(opts)
  opts = utils.normalize_opts(opts)

  local preview
  if fn.executable("bat") == 1 then
    preview = vim.env.FZF_PREVIEW_COMMAND .. ' {}'
  else
    preview = 'type "$0"'
  end

  coroutine.wrap(function ()
    local gitsrc = 'git diff-tree --no-color --relative --no-commit-id --name-only -r HEAD HEAD~1'
    local tip = term.green .. 'CTRL-R' .. term.reset .. ' to paste content at cursor. ' ..
                term.green .. 'CTRL-S' .. term.reset .. ' to open in horizontal split. ' ..
                term.green .. 'CTRL-V' .. term.reset .. ' to open in vertical split. ' ..
                term.green .. 'CTRL-T' .. term.reset .. ' to open in new tab. '
    local fzfcommand = (term.fzf_colors .. '--expect=ctrl-s,ctrl-t,ctrl-v,ctrl-r,ctrl-p --header="' .. tip .. '" --ansi --multi --prompt="GitFiles Last Committed> " --delimiter="' .. utils.delim .. '" --preview=%s'):format(fn.shellescape(preview))
    local choices = opts.fzf(gitsrc, fzfcommand)
    if not choices then return end

    local vimcmd
    if choices[1] == "ctrl-t" then
      vimcmd = "tabnew"
    elseif choices[1] == "ctrl-v" then
      vimcmd = "botright vs"
    elseif choices[1] == "ctrl-s" then
      vimcmd = "new"
    elseif choices[1] == "ctrl-r" then
      vimcmd = "r"
    elseif choices[1] == "ctrl-p" then
      -- paste list of selected files
    else
      vimcmd = "e"
    end

    for i=2, #choices do
      vim.cmd(vimcmd .. " " .. fn.fnameescape(choices[i]))
    end
  end)()
end
