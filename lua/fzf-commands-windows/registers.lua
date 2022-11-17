local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)
  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = ('--header-lines=2 --ansi --multi --expect=ctrl-p,ctrl-q --prompt="Registers> "')
    local items = {}

    local reglist = ('%s'):format(api.exec('registers', { output = true }))

    for line in reglist:gmatch('([^\n]*)\n?') do
      local linefmt = string.format("%q", line)
      local _, reg, regdata = string.match(linefmt, '^"%s*(%a)%s+\\"(%S+)%s+(.*)"$')
      if reg then
        reg = string.gsub(reg, [["(.)]], '%1') -- Remove register prefix
        reg = string.gsub(reg, [[\(.)]], '%1') -- Unescape
        regdata = string.gsub(regdata, [[\(.)]], '%1') -- Unescape
        regdata = string.gsub(regdata, '(^J)', '')
        regdata = string.gsub(regdata, '(^M)', '')
        regdata = string.gsub(regdata, '(^I)', ' ')
        local item_string = string.format("%-20s", term.red .. ' ' .. tostring(reg) .. ' ' .. term.reset) ..
                            regdata
        table.insert(items, item_string)
      end
    end

    local head = 'Reg'
    local tip = term.green .. 'ENTER' .. term.reset .. ' to paste linewise after cursor. ' ..
                term.green .. 'CTRL-P' .. term.reset .. ' to paste before. ' ..
                term.green .. 'CTRL-Q' .. term.reset .. ' to delete register(s). '

    table.insert(items, 1, head)
    table.insert(items, 1, tip)

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    local cmd
    if lines[1] == "" then
      for i = 2, #lines do
        local reg, _ = string.match(lines[i], '^%s*(%S)')
        cmd = 'silent put ' .. reg
        api.command(cmd)
      end
    elseif lines[1] == "ctrl-p" then
      for i = 2, #lines do
        local reg, _ = string.match(lines[i], '^%s*(%S)')
        cmd = 'silent put! ' .. reg
        api.command(cmd)
      end
    elseif lines[1] == "ctrl-q" then
      for i = 2, #lines do
        local reg, _ = string.match(lines[i], '^%s*(%S)')
        cmd = 'let @' .. reg .. '=""'
        api.command(cmd)
      end
    end

  end)()
end
