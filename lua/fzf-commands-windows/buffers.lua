local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

return function(options)

  -- port from fzf.vim
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

  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = (term.fzf_colors .. '--header-lines=2 --ansi --multi --expect=ctrl-q,ctrl-s,ctrl-v,ctrl-t --prompt="Buffers> "')
    local items = {}

    local reglist = ('%s'):format(api.exec('buffers', { output = true }))

    for line in reglist:gmatch('([^\n]*)\n?') do
      local bufnum, status, active, filepath, linenum = string.match(line, '^%s*(%d+)%s+(%p?)(%w)%s+"([^"]+)"%s*line%s*(%d+)')
      if bufnum then
        -- reg = string.gsub(reg, [[\(.)]], '%1') -- Unescape
        -- regdata = string.gsub(regdata, [[\(.)]], '%1') -- Unescape
        if filepath == "" then
          filepath = "[No name]"
        end
        local item_string = string.format("%-18s", term.red .. ' ' .. tostring(bufnum) .. ' ' .. term.reset) ..
                            string.format("%-20s", term.green .. ' ' .. tostring(status) .. ' ' .. term.reset) ..
                            filepath
        table.insert(items, item_string)
      end
    end

    local head = ' #    ?     file'
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

    -- TODO Эта функция не сработает, если нужный нам буфер находится в фоне
    -- Нужно вызывать функцию nvim_win_set_buf и передавать ей window handle,
    -- который похоже начинается от 1000, и номер буфера
    -- fn.bufwinid возвращает окно только если буфер в этом окне показывается!
    -- Вообще получается, что скрытый буфер ни с каким окном не связан,
    -- а значит его можно показывать прямо на месте? Опять-таки, скрытые
    -- буфера можно открывать в новых вкладках, новых сплитах
    local cmd
    if lines[1] == "" then -- you can go only to one buffer on keypress
      local bufnum, _ = tonumber(string.match(lines[2], '^%s*(%d+)'))
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
        local bufnum, _ = string.match(lines[i], '^%s*(%d+)')
        cmd = 'bdelete! ' .. bufnum
        api.command(cmd)
      end
    end
    if lines[1] == "ctrl-s" then
      for i = 2, #lines do
        local bufnum, _ = tonumber(string.match(lines[i], '^%s*(%d+)'))
        cmd = 'split ' .. fn.getbufinfo(bufnum)[1].name
        api.command(cmd)
      end
    end
    if lines[1] == "ctrl-v" then
      for i = 2, #lines do
        local bufnum, _ = tonumber(string.match(lines[i], '^%s*(%d+)'))
        cmd = 'vsplit ' .. fn.getbufinfo(bufnum)[1].name
        api.command(cmd)
      end
    end
    if lines[1] == "ctrl-t" then
      for i = 2, #lines do
        local bufnum, _ = string.match(lines[i], '^%s*(%d+)')
        cmd = 'tabnew ' .. fn.getbufinfo(bufnum)[1].name
        api.command(cmd)
      end
    end
  end)()
end
