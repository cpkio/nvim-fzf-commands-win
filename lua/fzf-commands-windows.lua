local M = {}

local function run_module(name)
  return function(...)
    require(name)(...)
  end
end

M.files = run_module("fzf-commands-windows.files")
M.marks = run_module("fzf-commands-windows.marks")
M.registers = run_module("fzf-commands-windows.registers")
M.buffers = run_module("fzf-commands-windows.buffers")
M.bufferlines = run_module("fzf-commands-windows.bufferlines")
M.lines = run_module("fzf-commands-windows.lines")
M.rg = run_module("fzf-commands-windows.rg")
M.ug = run_module("fzf-commands-windows.ug")
M.gdiff = run_module("fzf-commands-windows.gdiff")
M.filetypes = run_module("fzf-commands-windows.filetypes")
M.ctags = run_module("fzf-commands-windows.ctags")
M.commands_history = run_module("fzf-commands-windows.commands_history")
M.search_history = run_module("fzf-commands-windows.search_history")
M.directories = run_module("fzf-commands-windows.directories")
M.pgrep = run_module("fzf-commands-windows.pgrep")
M.bookmarks = run_module("fzf-commands-windows.bookmarks")
M.gitbranch = run_module("fzf-commands-windows.gitbranch")
M.gitfiles = run_module("fzf-commands-windows.gitfiles")
M.gitfileslastcommitted = run_module("fzf-commands-windows.gitfileslastcommitted")

return M
