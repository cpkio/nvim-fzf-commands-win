local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local action = require "fzf.actions".action

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

  -- local preview
  -- if fn.executable("bat") == 1 then
  --   -- Adding {} to preview command is needed for me because other preview
  --   -- placeholders can be other ones
  --   preview = vim.env.FZF_PREVIEW_COMMAND .. ' {}'
  -- else
  --   preview = 'type "$0"'
  -- end


-- local function get_preview_line_range(parsed, fzf_lines)
--   local line_start = parsed.row - (fzf_lines / 2)
--   if line_start < 1 then
--     line_start = 1
--   else
--     line_start = math.floor(line_start)
--   end

--   -- the minus one prevents an off by one error, because these are line INCLUSIVE
--   local line_end = math.floor(parsed.row + (fzf_lines / 2)) - 1

--   return line_start, line_end
-- end

-- local function bat_preview(parsed, fzf_lines)
--   local line_start, line_end = get_preview_line_range(parsed, fzf_lines)
--   local cmd = "bat --style=numbers --color always " .. vim.fn.shellescape(parsed.filename) ..
--     " --highlight-line " .. tostring(parsed.row) ..
--     " --line-range " .. tostring(line_start) .. ":" .. tostring(line_end)
--   return vim.fn.system(cmd)
-- end

-- local function head_tail_preview(parsed, fzf_lines)
--   local line_start, line_end = get_preview_line_range(parsed, fzf_lines)
--   local output =  vim.fn.systemlist("tail --lines=+" .. tostring(line_start) .. " " .. vim.fn.shellescape(parsed.filename) ..
--     "| head -n " .. tostring(line_end - line_start))

--   local row_index = parsed.row - (line_start - 1)
--   output[row_index] = term.red .. output[row_index] .. term.reset
--   return output
-- end

-- local preview_action = action(function (lines, fzf_lines)
--   fzf_lines = tonumber(fzf_lines)
--   local line = lines[1]
--   local parsed = parse_vimgrep_line(line)
--   if has_bat then
--     return bat_preview(parsed, fzf_lines)
--   else
--     return head_tail_preview(parsed, fzf_lines)
--   end
-- end)


return function(opts, pattern)
  local prompt = "Rg> "
  if not pattern then pattern = "^(?=.)"; prompt = "XX> "  end

  opts = utils.normalize_opts(opts)
  coroutine.wrap(function ()
    local rgcmd = 'rg --vimgrep --pcre2 --no-heading --field-match-separator=' .. rg_delimiter .. ' ' .. vim.fn.shellescape(pattern)
    local choices = opts.fzf(rgcmd, '--delimiter="' .. rg_delimiter .. '" --multi --ansi --expect=ctrl-t,ctrl-s,ctrl-v --prompt="Rg> "'
                -- '--preview-window=+{2}-5:hidden:border-left' ..
                -- ' --highlight-line={2} {1}' ..
                -- ('--preview=%s'):format(fn.shellescape(preview))
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
