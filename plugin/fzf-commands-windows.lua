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
  { nargs = '?' }
)
