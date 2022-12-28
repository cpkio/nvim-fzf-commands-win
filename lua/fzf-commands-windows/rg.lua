local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
-- local action = require "fzf.actions".action

local fn, api = utils.helpers()

local rg_delimiter=' '

local function open_file(window_cmd, filename, row, col)
  vim.cmd(window_cmd .. " ".. vim.fn.fnameescape(filename))
  api.win_set_cursor(0, {row, col - 1})
  -- center the window
  vim.cmd "normal! zz"
end

local function parse_vimgrep_line(line)
  local parsed_content = {string.match(line, "(.-)" .. rg_delimiter .. "(%d+)" .. rg_delimiter .. "(%d+)" .. ".*")}
  local filename = parsed_content[1]
  local row = tonumber(parsed_content[2])
  local col = tonumber(parsed_content[3])
  return {
    filename = filename,
    row = row,
    col = col
  }
end

local has_bat = vim.fn.executable("bat")

return function(opts, pattern)
  local prompt = "Rg> "
  if pattern then prompt = "Rg (" .. fn.shellescape(pattern) .. ")> " end
  if not pattern then pattern = "^(?=.)" end

  local preview
  if fn.executable("bat") == 1 then
    preview = vim.env.FZF_PREVIEW_COMMAND .. ' --highlight-line={2} {1}'
  end

  local rgcmd = 'rg --vimgrep --pcre2 --no-heading --field-match-separator=' .. rg_delimiter .. ' ' .. fn.shellescape(pattern)
  opts = utils.normalize_opts(opts)

  coroutine.wrap(function ()
    local choices = opts.fzf(rgcmd, term.fzf_colors .. '--delimiter="' .. rg_delimiter .. '" --multi --ansi --expect=ctrl-t,ctrl-s,ctrl-v --prompt="' .. prompt .. ('" --preview-window=+{2}-3 --preview=%s'):format(fn.shellescape(preview))
    )

    if not choices then return end

    local cmd

    if choices[1] == "" then
      cmd = "e"
    elseif choices[1] == "ctrl-v" then
      cmd = "vsp"
    elseif choices[1] == "ctrl-t" then
      cmd = "tabnew"
    elseif choices[1] == "ctrl-s" then
      cmd = "sp"
    end

    -- TODO add to quickfix list

    for i=2,#choices do
      local choice = choices[i]
      local parsed_content = parse_vimgrep_line(choice)
      open_file(cmd,
        parsed_content.filename,
        parsed_content.row,
        parsed_content.col)
    end
  end)()
end
