local utils = require "fzf-commands-windows.utils"
local term = require "fzf-commands-windows.term"
local fn = utils.helpers()

return function(opts)
  assert(fn.executable("fd") == 1)
  opts = utils.normalize_opts(opts)

  local extra = ''
  if opts.extra then
    extra = fn.join(opts.extra, ' ')
  end

  -- local preview = 'git --git-dir=./{2}/.git --work-tree=./{2} show-branch'
  local preview = 'git --git-dir=./{2}/.git --work-tree=./{2} log --color=always --oneline --all --abbrev-commit --graph --decorate'

  local cmd = {
    'fd',
    '--color', 'never',
    '--threads', '8',
    '--type=directory',
    '-d', '1',
    '--exec', 'git', '--git-dir={}/.git', '--work-tree={}', 'rev-parse', '--abbrev-ref', 'HEAD', '--path-format=relative', '--show-toplevel'
  }

  local res = {}
  local function on_exit(obj)
    local capture = vim.split(obj.stdout, "\n", { plain = true, trimempty = true })
    assert(#capture%2 == 0)
    for i = 1, #capture/2 do
      table.insert(
        res,
        utils.pad( term.green .. capture[i*2 - 1] .. term.reset , 20) ..
        utils.delim ..
        term.blue .. capture[i*2] .. term.reset
    )
    end
  end

  vim.system(cmd, { text = true }, on_exit):wait()

  coroutine.wrap(function ()
    local choices = opts.fzf(res,
      (term.fzf_colors .. ' --ansi --delimiter="' .. utils.delim .. '" --prompt="Branches> " --preview=%s'):format(fn.shellescape(preview)))
  end)()
end
