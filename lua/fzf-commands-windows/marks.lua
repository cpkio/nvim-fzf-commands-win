local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()


return function(options)

  local preview
  if fn.executable("bat") == 1 then
    -- Adding {} to preview command is needed for me because other preview
    -- placeholders can be other ones
    preview = vim.env.FZF_PREVIEW_COMMAND .. ' {3}'
  else
    preview = 'type "$0"'
  end

  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = ('--header-lines=2 --ansi --multi --expect=ctrl-t,ctrl-s,ctrl-v,ctrl-q --prompt="Marks> " --preview=%s'):format(fn.shellescape(preview))
    local items = {}

    local mrklist = ('%s'):format(api.exec('marks', { output = true }))

    for line in mrklist:gmatch('([^\n]*)\n?') do
      local linefmt = string.format("%q", line)
      local mrk, ln, _, mrkdata = string.match(linefmt, '^"%s*(%S*)%s+(%d+)%s+(%d+)%s+([^"]*)')
      if mrk then
        mrk = string.gsub(mrk, [[\(.)]], '%1')
        mrkdata = string.gsub(mrkdata, [[\(.)]], '%1')
        local item_string = string.format("%-20s", term.red .. ' ' .. tostring(mrk) .. ' ' .. term.reset) ..
                            string.format("%-20s", term.brightblue .. tostring(ln) .. term.reset) ..
                            mrkdata
        table.insert(items, item_string)
      end
    end

    local head = 'Mark  Col'
    local tip = term.green .. 'CTRL-T' .. term.reset .. ' to open in new tab. ' ..
                term.green .. 'CTRL-S' .. term.reset .. ' to open in split. ' ..
                term.green .. 'CTRL-V' .. term.reset .. ' to open in vertical split. ' ..
                term.green .. 'CTRL-Q' .. term.reset .. ' to delete mark(s). '

    table.insert(items, 1, head)
    table.insert(items, 1, tip)

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end


    if lines[1] == "" then
        local mrk, _ = string.match(lines[2], '^%s*(%S*)')
        local cmd = "normal! `" .. mrk .. "zz"
    end
    if lines[1] == "ctrl-t" then
      for i = 2, #lines do
        local mrk, _ = string.match(lines[i], '^%s*(%S*)')
        local cmd = "normal! `" .. mrk .. "zz"
        cmd = "tab split | " .. cmd
      end
    end
    if lines[1] == "ctrl-v" then
      for i = 2, #lines do
        local mrk, _ = string.match(lines[i], '^%s*(%S*)')
        local cmd = "normal! `" .. mrk .. "zz"
        cmd = "vertical split | " .. cmd
      end
    end
    if lines[1] == "ctrl-s" then
      for i = 2, #lines do
        local mrk, _ = string.match(lines[i], '^%s*(%S*)')
        local cmd = "normal! `" .. mrk .. "zz"
        cmd = "split | " .. cmd
      end
    end
    if lines[1] == "ctrl-q" then
      for i = 2, #lines do
        local m, _ = string.match(lines[i], '^%s*(%S*)')
        if m == '"' then m = [[\"]] end -- if we meet double quote in output stream
        if m == "'" then m = [[\']] end -- if we meet single quote in output stream
        local cmd = "delmark " .. m
        api.command(cmd)
      end
      api.command('wshada!')
    end
  end)()
end
