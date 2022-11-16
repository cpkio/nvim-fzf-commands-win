local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()


return function(options)
  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = "--ansi --multi --expect=ctrl-t,ctrl-s,ctrl-v,ctrl-q"
    local items = {}

    local mrklist = ('%s'):format(api.exec('marks', { output = true }))

    for line in mrklist:gmatch('([^\n]*)\n?') do
      local linefmt = string.format("%q", line)
      local mrk, ln, _, mrkdata = string.match(linefmt, '^"%s*(%S*)%s+(%d+)%s+(%d+)%s+([^"]*)')
      if mrk then
        mrk = string.gsub(mrk, [[\(.)]], '%1')
        mrkdata = string.gsub(mrkdata, [[\(.)]], '%1')
        local item_string = string.format("%-16s", term.red .. ' ' .. tostring(mrk) .. ' ' .. term.reset) ..
                            string.format("%-20s", term.brightblue .. tostring(ln) .. term.reset) ..
                            mrkdata
        table.insert(items, item_string)
      end
    end

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    local mrk, _ = string.match(lines[2], '^%s*(%S*)')
    local cmd = "normal! `" .. mrk .. "zz"

    if lines[1] == "" then
    elseif lines[1] == "ctrl-t" then
      cmd = "tab split | " .. cmd
    elseif lines[1] == "ctrl-v" then
      cmd = "vertical split | " .. cmd
    elseif lines[1] == "ctrl-s" then
      cmd = "split | " .. cmd
    elseif lines[1] == "ctrl-q" then
      for i = 2, #lines do
        local m, _ = string.match(lines[i], '^%s*(%S*)')
        if m == '"' then m = [[\"]] end -- обработка случая, когда марка является двойной кавычкой
        if m == "'" then m = [[\']] end -- обработка случая, когда марка является ординарной кавычкой
        cmd = "delmark " .. m
        api.command(cmd)
        vim.notify('Mark ' .. m .. ' deleted')
      end
      cmd = "echo Marks deleted"
    end
    api.command(cmd)
  end)()
end
