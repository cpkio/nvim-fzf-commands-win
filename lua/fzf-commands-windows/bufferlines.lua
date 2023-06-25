local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

local rg_delimiter=' '
local ui_w = vim.api.nvim_list_uis()[1].width
local ui_h = vim.api.nvim_list_uis()[1].height
local margin_horz = 20
local margin_vert = 20

local winopts = {
  border = "single",
  title = "Scratch buffer",
  title_pos = "center",
  width = ui_w - 2*margin_horz,
  height = ui_h - 2*margin_vert,
  relative = "editor",
  row = margin_vert,
  col = margin_horz,
}


return function(options)
  coroutine.wrap(function()
    options = utils.normalize_opts(options)
    local opts = (term.fzf_colors .. '--reverse --header-lines=1 --multi --expect=ctrl-l,ctrl-p --ansi --prompt="BLines> "')
    local items = {}

    local buflines = api.buf_get_lines(0,0,-1,0)

    for i, line in pairs(buflines) do
      if #line > 0 then
        line = string.format("%-18s", term.red .. ' ' .. tostring(i) .. ' ' .. term.reset) .. rg_delimiter .. line
        table.insert(items, line)
      end
    end

    local tip = term.green .. 'ENTER' .. term.reset .. ' to push to Quickfix list. ' ..
                term.green .. 'CTRL-L' .. term.reset .. ' to push to Locations list. ' ..
                term.green .. 'CTRL-P' .. term.reset .. ' to paste to new file.'

    table.insert(items, 1, tip)

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    if lines[1] == "" then
      if #lines == 2 then
        local linenum, _ = string.match(lines[2], '^%s*(%d+)')
        api.command(linenum)
      else
        local bufnum = api.get_current_buf()
        local itemsqf = {}
        for j = 2, #lines do
          local linenum, line = string.match(lines[j], '^%s*(%d+)%s*(%S.+)')
          table.insert(itemsqf, { bufnr = bufnum, lnum = tonumber(linenum), text = line })
        end
        fn.setqflist({},' ',{ id = 'FzfBLines', items = itemsqf, title = 'FzfBLines'})
        api.command('botright copen')
      end
    end

    if lines[1] == "ctrl-l" then
      if #lines == 2 then
        local linenum, _ = string.match(lines[2], '^%s*(%d+)')
        api.command(linenum)
      else
        local bufnum = api.get_current_buf()
        local itemsqf = {}
        for j = 2, #lines do
          local linenum, line = string.match(lines[j], '^%s*(%d+)%s*(%S.+)')
          table.insert(itemsqf, { bufnr = bufnum, lnum = tonumber(linenum), text = line })
        end
        fn.setloclist(fn.win_getid(),{},' ',{ id = 'FzfBLines', items = itemsqf, title = 'FzfBLines'})
        api.command('botright lopen')
      end
    end

    if lines[1] == "ctrl-p" then
      local tempbuffer = vim.api.nvim_create_buf(true, true)
      if #lines == 2 then
        local line = string.match(lines[2], '^.+'..rg_delimiter..'(.+)')
        vim.api.nvim_buf_set_lines(tempbuffer, 0, -1, true, { line })
      else
        local buflines = {}
        for j = 2, #lines do
          local line = string.match(lines[j], '^.+'..rg_delimiter..'(.+)')
          table.insert(buflines, line)
        end
        vim.api.nvim_buf_set_lines(tempbuffer, 0, -1, true, buflines)
      end
      vim.api.nvim_open_win(tempbuffer, true, winopts)
    end

  end)()
end
