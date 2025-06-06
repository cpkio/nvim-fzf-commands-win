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
vim.api.nvim_create_user_command('Files',
  function(opts)
    require("fzf-commands-windows").files({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('FilesHidden',
  function(opts)
    require("fzf-commands-windows").files({
      fzf = fzfcmd, extra = {'--hidden', '--no-ignore'} }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('Lines',
  function(opts)
    require("fzf-commands-windows").lines({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('BLines',
  function(opts)
    require("fzf-commands-windows").bufferlines({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('Marks',
  function(opts)
    require("fzf-commands-windows").marks({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('Buffers',
  function(opts)
    require("fzf-commands-windows").buffers({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('Registers',
  function(opts)
    require("fzf-commands-windows").registers({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('FileTypes',
  function(opts)
    require("fzf-commands-windows").filetypes({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('CommandsHistory',
  function(opts)
    require("fzf-commands-windows").commands_history({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('SearchesHistory',
  function(opts)
    require("fzf-commands-windows").search_history({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('Directories',
  function(opts)
    require("fzf-commands-windows").directories({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('GitFiles',
  function(opts)
    require("fzf-commands-windows").gitfiles({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
vim.api.nvim_create_user_command('GitFilesLastCommitted',
  function(opts)
    require("fzf-commands-windows").gitfileslastcommitted({
      fzf = fzfcmd }, opts.args)
  end,
  {}
)
