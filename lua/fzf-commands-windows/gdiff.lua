local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local action = require "fzf.actions".action

local fn, api = utils.helpers()

local d_delimiter = ' '

return function(opts)
  local buffer_number = -1

  local function log(_, data)
    if data then
      local r = {}
      for _, v in ipairs(data) do
        local w, _ = v:gsub('\r', '')
        table.insert(r, w)
      end
      vim.api.nvim_buf_set_lines(buffer_number, -1, -1, true, r)
    end
  end

  local function open_buffer()
    if buffer_number == -1 then
      vim.api.nvim_command('botright vnew')
      buffer_number = vim.api.nvim_get_current_buf()
    end
  end
  opts = utils.normalize_opts(opts)
  coroutine.wrap(function ()
    local fname = fn.fnamemodify(api.buf_get_name(0), ":t") -- барахлит функция на многооконных раскладках, но ладно
    local gitsrc = "git log --all --pretty=format:%H" .. d_delimiter .."%s" .. d_delimiter .. "%d -- *".. fname
    local fzfpreview = "git diff {1} -- *" .. fname .. " | delta --wrap-max-lines=unlimited " ..
    '--file-style=white                               ' ..

    '--minus-style=brightred                          ' ..
    '--minus-non-emph-style=brightred                 ' ..
    '--minus-emph-style=brightyellow                  ' ..
    '--minus-empty-line-marker-style=brightred        ' ..

    '--zero-style=white                               ' ..

    '--plus-style=yellow                              ' ..
    '--plus-non-emph-style=yellow                     ' ..
    '--plus-emph-style=brightyellow                   ' ..
    '--plus-empty-line-marker-style=yellow            ' ..

 -- '--grep-file-style=blue                           ' ..
 -- '--grep-line-number-style=blue                    ' ..
 -- '--whitespace-error-style=reverse brightblue      ' ..

    '--line-numbers-minus-style=brightred             ' ..
    '--line-numbers-zero-style=white                  ' ..
    '--line-numbers-plus-style=yellow                 ' ..
    '--width=%FZF_PREVIEW_COLUMNS%'
    local fzfcommand = term.fzf_colors .. '--prompt="GDiff> " --delimiter=' .. d_delimiter .. ' --preview-window=up:border-none --preview=' .. fn.shellescape(fzfpreview)
    local choices = opts.fzf(gitsrc, fzfcommand) -- проблема в fzfcommand
    if not choices then return end
    local s = vim.split(choices[1], d_delimiter)
    local fnm = './' .. vim.fn.expand('%'):gsub('\\','/')
    open_buffer()
    vim.fn.jobstart({'git', 'show', '-t', s[1]..':'..fnm }, {
      stdout_buffered = true,
      overlapped = true,
      on_stdout = log,
      on_stderr = log
    })

  end)()
end
