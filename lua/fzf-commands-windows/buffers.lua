local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

local function locate(bufnum)
  for tab = 1, vim.fn.tabpagenr('$') do
    local buffers = vim.fn.tabpagebuflist(tab)
    for k, buf in pairs(buffers) do
      if bufnum == buf then
        return tab, k
      end
    end
  end
  return 0, 0
end

local function buf(line)
  local bufnum, _ = tonumber(string.match(line, '^%s*(%d+)'))
  return bufnum
end

return function(options)

  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = (term.fzf_colors .. '--header-lines=2 --ansi --multi --expect=ctrl-q,ctrl-s,ctrl-v,ctrl-t --prompt="Buffers> "')
    local items = {}

    local reglist = ('%s'):format(api.exec('buffers', { output = true }))

    for line in reglist:gmatch('([^\n]*)\n?') do
      local bufnum, status, active, ro, modified, filepath, linenum = string.match(line, '^%s*(%d+)%s+(%p?)(%w)(%=?)%s*(%+?)%s*"([^"]+)"%s*line%s*(%d+)')
      print(
        "bufnum `"   ,  bufnum   ,'`',
        "status `"   ,  status   ,'`',
        "active `"   ,  active   ,'`',
        "ro `"       ,  ro       ,'`',
        "modified `" ,  modified ,'`',
        "filepath `" ,  filepath ,'`',
        "linenum `"  ,  linenum  ,'`'
      )
      if bufnum then
        if filepath == "" then
          filepath = "[No name]"
        end
        if modified == "+" then modified = "⚠" else modified = "  " end
        if ro == "=" then ro = "" else ro = "  " end
        local item_string = string.format("%-16s", term.green .. tostring(bufnum) .. term.reset) ..
                            string.format("%-14s", term.yellow .. tostring(modified) .. ' ' .. term.reset) ..
                            string.format("%-14s", term.brightred .. tostring(ro) .. ' ' .. term.reset) ..
                            term.blue .. filepath .. term.reset
        table.insert(items, item_string)
      end
    end

    local head = '  #  ?  r  file'
    local tip = term.green .. 'CTRL-Q' .. term.reset .. ' to delete buffer(s). ' ..
                term.green .. 'CTRL-S' .. term.reset .. ' to open in horizontal split. ' ..
                term.green .. 'CTRL-V' .. term.reset .. ' to open in vertical split. ' ..
                term.green .. 'CTRL-T' .. term.reset .. ' to open in new tab. '

    table.insert(items, 1, head)
    table.insert(items, 1, tip)

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

   local cmd
    if lines[1] == "" then
      local bufnum, _ = buf(lines[2])
      local bufinfo = fn.getbufinfo(bufnum)[1]
      if bufinfo.hidden == 1 then
        api.win_set_buf(fn.win_getid(), bufnum)
      end
      if bufinfo.hidden == 0 then
        local t, w = locate(bufnum)
        api.command(t .. 'tabnext')
        api.command(w .. 'wincmd w')
        api.win_set_buf(fn.bufwinid(bufnum),bufnum)
      end
    end
    if lines[1] == "ctrl-q" then
      for i = 2, #lines do
        cmd = 'bdelete! ' .. buf(lines[i])
        api.command(cmd)
      end
    end
    if lines[1] == "ctrl-s" then
      for i = 2, #lines do
        local bufnum, _ = buf(lines[i])
        cmd = 'split ' .. fn.getbufinfo(bufnum)[1].name
        api.command(cmd)
      end
    end
    if lines[1] == "ctrl-v" then
      for i = 2, #lines do
        local bufnum, _ = buf(lines[i])
        cmd = 'vsplit ' .. fn.getbufinfo(bufnum)[1].name
        api.command(cmd)
      end
    end
    if lines[1] == "ctrl-t" then
      for i = 2, #lines do
        local bufnum, _ = buf(lines[i])
        cmd = 'tabedit ' .. fn.getbufinfo(bufnum)[1].name
        api.command(cmd)
      end
    end
  end)()
end
