local function make_color_ansi(color_of_16)
  return "\x1b[38;5;" .. tostring(color_of_16) .. "m"
end

local term = {}

term.reset = "\x1b[0m"
term.bold = "\x1b[1m"
term.italic = "\x1b[3m"
term.underline = "\x1b[4m"
term.reverse = "\x1b[7m"

term.black = "\x1b[30m"
term.red = "\x1b[31m"
term.green = "\x1b[32m"
term.yellow = "\x1b[33m"
term.blue = "\x1b[34m"
term.magenta = "\x1b[35m"
term.cyan = "\x1b[36m"
term.white = "\x1b[37m"
term.brightblack = "\x1b[90m"
term.brightred = "\x1b[91m"
term.brightgreen = "\x1b[92m"
term.brightyellow = "\x1b[93m"
term.brightblue = "\x1b[94m"
term.brightmagenta = "\x1b[95m"
term.brightcyan = "\x1b[96m"
term.brightwhite = "\x1b[97m"

term.fzf_colors = " --color=16,hl:3,selected-hl:3,fg+:2,gutter:-1,hl+:11,query:11,info:14,disabled:13,scrollbar:15,pointer:11 "

return term
