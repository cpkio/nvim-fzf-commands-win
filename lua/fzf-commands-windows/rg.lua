local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
-- local action = require "fzf.actions".action

local fn, api = utils.helpers()

local function open_file(window_cmd, filename, row, col)
  vim.cmd(window_cmd .. " ".. vim.fn.fnameescape(filename))
  api.win_set_cursor(0, {row, col - 1})
  vim.cmd "normal! zz"
end

local function parse_vimgrep_line(line)
  local parsed_content = {string.match(line, "(.-)" .. utils.delim .. "(%d+)" .. utils.delim .. "(%d+)" .. utils.delim .. "(.*)")}
  local filename = parsed_content[1]
  local row = tonumber(parsed_content[2])
  local col = tonumber(parsed_content[3])
  local text = parsed_content[4]
  return {
    filename = filename,
    row = row,
    col = col,
    text = text
  }
end

local function open_files(cmd, choices)
  for i=2,#choices do
    local choice = choices[i]
    local parsed_content = parse_vimgrep_line(choice)
    open_file(cmd,
      parsed_content.filename,
      parsed_content.row,
      parsed_content.col)
  end
end

local has_bat = vim.fn.executable("bat")

return function(opts, pattern)

  local nth = ''
  if opts.nth then
    nth = '--nth='..opts.nth
  end

  local extra = ''
  if opts.extra then
    extra = fn.join(opts.extra, ' ')
  end

  local prompt = "Rg> "; local header = ''
  if pattern then header = ' --header-first --header=' .. fn.shellescape(pattern) end
  if not pattern then pattern = "^(?=.)" end

  local preview
  if fn.executable("bat") == 1 then
    preview = vim.env.FZF_PREVIEW_COMMAND .. ' --highlight-line={2} {1}'
  end

  local rgcmd = 'rg --vimgrep --pcre2 --no-heading --smart-case --trim --color=ansi --colors=path:fg:magenta --colors=line:fg:green --colors=column:fg:blue --colors=match:fg:yellow --field-match-separator="' .. utils.delim .. '" ' .. fn.shellescape(pattern)
  opts = utils.normalize_opts(opts)

  coroutine.wrap(function ()
    local choices = opts.fzf(rgcmd, term.fzf_colors .. extra .. ' --delimiter="' .. utils.delim .. '" ' .. nth .. ' --multi --ansi --layout=reverse --expect=ctrl-t,ctrl-s,ctrl-v --prompt=' .. fn.shellescape(prompt) .. header .. (' --preview-window=+{2}-3 --preview=%s'):format(fn.shellescape(preview))
    )

    if not choices then return end

    if choices[1] == "" then
      if #choices == 2 then
        open_files("e", choices)
      else
        local itemsqf = {}
        for j = 2, #choices do
          local parsed_content = parse_vimgrep_line(choices[j])
          table.insert(itemsqf,
                      { filename = parsed_content.filename,
                      lnum = parsed_content.row,
                      col = parsed_content.col,
                      vcol = 1,
                      text = parsed_content.text
          })
        end
        fn.setqflist({}, ' ', { items = itemsqf, title = 'FzfRg' })
        api.command('botright copen')
      end
    elseif choices[1] == "ctrl-v" then
      open_files("vsp", choices)
    elseif choices[1] == "ctrl-t" then
      open_files("tabnew", choices)
    elseif choices[1] == "ctrl-s" then
      open_files("sp", choices)
    end

  end)()
end
