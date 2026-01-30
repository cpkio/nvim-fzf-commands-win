local uv = vim.loop
local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn, api = utils.helpers()

local _return = vim.schedule_wrap(function(data, opts)
  local _json = fn.split(data, '\n')
  local _uniques = {}
  for _, v in pairs(_json) do
    local entry = fn.json_decode(v)
    if entry.data.submatches then
      local _line = entry.data.line_number
      for _, w in pairs(entry.data.submatches) do
        if _uniques[w.match.text] then
          _uniques[w.match.text].count = _uniques[w.match.text].count + 1
          table.insert(_uniques[w.match.text].locations, { line = _line, column = vim.str_utfindex(entry.data.lines.text, w.start) + 1 })
        else
          _uniques[w.match.text] = {
            count = 1,
            locations = {
              { line = _line, column = vim.str_utfindex(entry.data.lines.text, w.start) + 1 }
            }
          }
        end
      end
    end
  end

  local items = { term.green .. 'ENTER' .. term.reset .. ' to expand entry locations to QuickFix list' }

  local function by_match(a, b)
    return a < b
  end

  local _keys = {}
  for _key in pairs(_uniques) do
      table.insert(_keys, _key)
  end
  table.sort(_keys)

  for _, k in ipairs(_keys) do
    table.insert(items,
      term.green .. '('.. _uniques[k].count ..')' .. term.reset ..
      utils.delim ..
      term.blue .. k .. term.reset
    )
  end

  local opts = utils.normalize_opts(opts)
  local prompt = 'Uniques> '

  coroutine.wrap(function()
    local choices = opts.fzf(items, term.fzf_colors .. ' --header-lines=1 --multi --delimiter="' .. utils.delim .. '" --nth=2 --no-sort --tac --ansi --prompt="' .. prompt .. '"')

    if not choices then return end

    local allqf = {}
    for _, value in pairs(choices) do
      local itemsqf = {}
      local _res = string.match(value, '%(%d+%)' .. utils.delim .. '(.+)')

      for _, v in pairs(_uniques[_res].locations) do
        table.insert(itemsqf, {
          bufnr = 0,
          vcol = 1,
          filename = fn.fnamemodify(api.buf_get_name(0), ':p:.'),
          lnum = v.line,
          col = v.column,
          text = _res })
      end
      vim.list_extend(allqf, itemsqf)
    end
    local qfsize = math.min(#allqf, 9)

    fn.setqflist({}, ' ', { items = allqf, title = 'FzfRg' })
    vim.cmd('copen' .. qfsize)
  end)()

end)


return function(opts, pattern)

  local pipe = function(text, command, args)
    local pipein = uv.new_pipe(false)
    local pipeout = uv.new_pipe(false)

    if command then
      local handle, pid = uv.spawn(command, {
        args = args,
        stdio = { pipeout, pipein },
      }, function(code, signal)
          if code == 1 then
            vim.notify("Current buffer has no data for Ripgrep")
          end
        end)

      local d = ''
      uv.read_start(pipein, function(err, data)
        assert(not err, err)
        if data then
          d = d .. data
        end
        if not data then
          _return(d, opts)
        end
      end)

      uv.write(pipeout, text, nil)
      uv.shutdown(pipeout)
      uv.shutdown(pipein, function()
        uv.close(handle, function()
          vim.notify("process closed: " .. tostring(handle) .. ':' .. tostring(pid))
        end)
      end)
    else
      return
    end
  end

  local text = fn.join(api.buf_get_lines(0, 0 , -1, false), '\n')
  pipe(text, 'rg', { '--pcre2', '--json', pattern })
end
