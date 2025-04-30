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

  -- local preview = 'git --git-dir=./{1}/.git --work-tree=./{1} show-branch'
  local preview = 'git --git-dir=' .. vim.g.antora_docs_root .. '/{1}/.git --work-tree=' .. vim.g.antora_docs_root .. '/{1} branch --color=always --no-column' .. '&& echo:' ..
                  '&& git --git-dir=' .. vim.g.antora_docs_root .. '/{1}/.git --work-tree=' .. vim.g.antora_docs_root .. '/{1} log --color=always --oneline --all --abbrev-commit --graph --decorate' ..
                  '&& git --git-dir=' .. vim.g.antora_docs_root .. '/{1}/.git --work-tree=' .. vim.g.antora_docs_root .. '/{1} status'

  local cmd = {
    'fd',
    '--color', 'never',
    -- '--threads', '8',
    '--type=directory',
    '-d', '1',
    '--prune',
    '--exec', 'git', '--git-dir={}/.git', '--work-tree={}',
                     'rev-parse',
                     '--abbrev-ref', 'HEAD',
                     '--path-format=relative',
                     '--show-toplevel'
  }

  local res = {}
  local function on_exit(obj)
    local capture = vim.split(obj.stdout, "\n", { plain = true, trimempty = true })
    assert(#capture%2 == 0)
    for i = 1, #capture/2 do
      table.insert(
        res,
        term.blue .. string.format('%-30s', capture[i*2]) .. term.reset ..
        utils.delim ..
        term.green .. capture[i*2 - 1] .. term.reset
    )
    end
    table.sort(res)
  end

  vim.system(cmd, { text = true, cwd = vim.g.antora_docs_root }, on_exit):wait()

  coroutine.wrap(function ()
    local choices = opts.fzf(res,
      (term.fzf_colors .. ' --tiebreak=begin --ansi --delimiter="' .. utils.delim .. '" --prompt="Branches> " --preview=%s'):format(fn.shellescape(preview)))
  end)()
end
