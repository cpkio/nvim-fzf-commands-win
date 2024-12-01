local fzfwinopts = {
  border = false,
  relative = "editor",
  width = 280,
  noautocmd = true
}

local fzfcmd = function(contents, opts)
  return require("fzf").fzf(contents, opts, fzfwinopts)
end

vim.api.nvim_create_user_command('PGrep',
  function(opts)
    require("fzf-commands-windows").pgrep({
      fzf = fzfcmd }, opts.args)
  end,
  { nargs = 1 }
)

vim.api.nvim_create_user_command('Rg',
  function(opts)
    require("fzf-commands-windows").rg({
      fzf = fzfcmd }, opts.args)
  end,
  { nargs = 1 }
)

vim.api.nvim_create_user_command('Ug',
  function(opts)
    require("fzf-commands-windows").ug({
      fzf = fzfcmd }, opts.args)
  end,
  { nargs = 1 }
)
vim.api.nvim_create_user_command('UG',
  function(opts)
    require("fzf-commands-windows").ug({
      fzf = fzfcmd, hidden = true }, opts.args)
  end,
  { nargs = 1 }
)
vim.api.nvim_create_user_command('UgN',
  function(opts)
    require("fzf-commands-windows").ug({
      fzf = fzfcmd, inverse = true }, opts.args)
  end,
  { nargs = 1 }
)
vim.api.nvim_create_user_command('GitBranch',
  function(opts)
    require("fzf-commands-windows").gitbranch({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
