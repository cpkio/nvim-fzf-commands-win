local M = {}

local function run_module(name)
  return function(...)
    require(name)(...)
  end
end

M.files = run_module("fzf-commands-windows.files")
-- Run Files with custom options
-- require("fzf-commands-windows").files({ fzf = function(contents, options) return require("fzf").fzf(contents, options, { border = false, height = 50 }) end })

return M
