local M = {}

local function run_module(name)
  return function(...)
    require(name)(...)
  end
end

M.files = run_module("fzf-commands-windows.files")
-- Run Files with custom options
-- require("fzf-commands-windows").files({ fzf = function(contents, options) return require("fzf").fzf(contents, options, { border = false, height = 50 }) end })
M.marks = run_module("fzf-commands-windows.marks")
M.registers = run_module("fzf-commands-windows.registers")
M.buffers = run_module("fzf-commands-windows.buffers")
M.bufferlines = run_module("fzf-commands-windows.bufferlines")
M.lines = run_module("fzf-commands-windows.lines")
M.rg = run_module("fzf-commands-windows.rg")
M.gdiff = run_module("fzf-commands-windows.gdiff")
M.filetypes = run_module("fzf-commands-windows.filetypes")
M.ctags = run_module("fzf-commands-windows.ctags")

return M
