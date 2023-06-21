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
M.gdiff = run_module("fzf-commands-windows.gdiff")
M.filetypes = run_module("fzf-commands-windows.filetypes")
M.ctags = run_module("fzf-commands-windows.ctags")
M.commands_history = run_module("fzf-commands-windows.commands_history")
M.search_history = run_module("fzf-commands-windows.search_history")
M.directories = run_module("fzf-commands-windows.directories")

return M
