local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local utf = require "lua-utf8" -- sadly this is needed for non-ascii filenames

local fn, api = utils.helpers()

local rg_delimiter=' '

local has_bat = vim.fn.executable("bat")

local function parse_tag_line(line)
  local parsed_line = { utf.match(line, [[([^%c]+)%c([^%c]+)%c(%d*);/^[^%c]+%c(%l)]]) }
  local tag_text = parsed_line[1]
  local filename = parsed_line[2]
  local linenum = tonumber(parsed_line[3])
  local kind = parsed_line[4]
  return {
    filename = filename,
    linenum = linenum,
    tag = tag_text,
    kind = kind
  }
end

local function parse_fzf_line(line)
  local parsed_line = { utf.match(line, '^([^'..rg_delimiter..']+)'..rg_delimiter..'(%d+)') }
  local filename = parsed_line[1]
  local linenum = parsed_line[2]
  return {
    filename = filename,
    linenum = linenum,
  }
end

local function gettags()
  local tagopt = vim.fn.split(vim.api.nvim_get_option('tags'), ',')

  for _, tagfile in pairs(tagopt) do
    if vim.fn.filereadable(tagfile) > 0 then
      return vim.fn.readfile(tagfile)
    end
  end
  return nil
end

return function(options)

  local preview
  if fn.executable("bat") == 1 then
    preview = vim.env.FZF_PREVIEW_COMMAND .. ' --line-range={2}:+20 --highlight-line={2} {1}'
  end

  local opts = (term.fzf_colors .. '--expect=ctrl-s,ctrl-t,ctrl-v --delimiter=' .. rg_delimiter .. ' --nth=3 --header-lines=0 --ansi --prompt="Ctags> " --preview=%s'):format(fn.shellescape(preview))
  options = utils.normalize_opts(options)

  coroutine.wrap(function ()

    local items = {}

    if gettags() then
      for _, line in pairs(gettags()) do
        local ln = parse_tag_line(line)
        if ln.kind == "a" or ln.kind == "t" then
          local decorated_line = term.blue .. ln.filename .. term.reset .. rg_delimiter ..
                                term.green .. ln.linenum .. term.reset .. rg_delimiter ..
                                tostring(ln.tag)
          table.insert(items, decorated_line)
        end
      end
    else
      vim.api.nvim_err_writeln('Tags file not found')
      return
    end

    local lines = options.fzf(items, opts)
    if not lines then
      return
    end

    local parsed_fzf = parse_fzf_line(lines[2])

    local vimcmd
    if lines[1] == "ctrl-t" then
      vimcmd = "tabnew"
    elseif lines[1] == "ctrl-v" then
      vimcmd = "vnew"
    elseif lines[1] == "ctrl-s" then
      vimcmd = "new"
    else
      vimcmd = "e"
    end

    vim.cmd(vimcmd .. " " .. fn.fnameescape(parsed_fzf.filename))
    vim.cmd(parsed_fzf.linenum)

  end)()
end
