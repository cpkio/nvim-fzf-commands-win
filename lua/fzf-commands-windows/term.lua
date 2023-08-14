local function make_color_ansi(color_of_16)
  return "\x1b[38;5;" .. tostring(color_of_16) .. "m"
end

local term = {}

term.reset = "\x1b[0m"
term.bold = "\x1b[1m"
term.italic = "\x1b[3m"
term.underline = "\x1b[4m"
term.reverse = "\x1b[7m"

term.black = "\x1b[38;5;0m"
term.red = "\x1b[38;5;1m"
term.green = "\x1b[38;5;2m"
term.yellow = "\x1b[38;5;3m"
term.blue = "\x1b[38;5;4m"
term.magenta = "\x1b[38;5;5m"
term.cyan = "\x1b[38;5;6m"
term.white = "\x1b[38;5;7m"
term.brightblack = "\x1b[38;5;8m"
term.brightred = "\x1b[38;5;9m"
term.brightgreen = "\x1b[38;5;10m"
term.brightyellow = "\x1b[38;5;11m"
term.brightblue = "\x1b[38;5;12m"
term.brightmagenta = "\x1b[38;5;13m"
term.brightcyan = "\x1b[38;5;14m"
term.brightwhite = "\x1b[38;5;15m"

term.fzf_colors = " --color=16,hl:3,fg+:2,hl+:11,query:11,info:14,disabled:13,scrollbar:15 "

return term
