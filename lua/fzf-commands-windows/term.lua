local function make_color_ansi(color_of_16)
  return "\x1b[38;5;" .. tostring(color_of_16) .. "m"
end

local function make_color_24(color)
  local red16 = string.sub(color, 2, 3)
  local green16 = string.sub(color, 4, 5)
  local blue16 = string.sub(color, 5, 6)
  local red = tonumber(red16, 16)
  local green = tonumber(green16, 16)
  local blue = tonumber(blue16, 16)
  return "\x1b[38;2;" .. red .. ";" .. green .. ";" .. blue .. "m"
end

local palette = {
	[0] = '#282c34',
	[1] = '#61afef',
	[2] = '#98c379',
	[3] = '#56b6c2',
	[4] = '#d19a66',
	[5] = '#c678dd',
	[6] = '#e5c07b',
	[7] = '#5c6370',
	[8] = '#2c323c',
	[9] = '#528bff',
	[10] = '#181a1f',
	[11] = '#3e4452',
	[12] = '#e06c75',
	[13] = '#be5046',
	[14] = '#e2f9fc',
	[15] = '#abb2bf',
}

local term = {}

term.reset = "\x1b[0m"
term.bold = "\x1b[1m"
term.italic = "\x1b[3m"
term.underline = "\x1b[4m"
term.reverse = "\x1b[7m"


if vim.opt.termguicolors._value then
  term.black =	make_color_24(palette[0])
  term.red =	make_color_24(palette[1])
  term.green =	make_color_24(palette[2])
  term.yellow =	make_color_24(palette[3])
  term.blue =	make_color_24(palette[4])
  term.magenta =	make_color_24(palette[5])
  term.cyan =	make_color_24(palette[6])
  term.white =	make_color_24(palette[7])
  term.brightblack =	make_color_24(palette[8])
  term.brightred =	make_color_24(palette[9])
  term.brightgreen =	make_color_24(palette[10])
  term.brightyellow =	make_color_24(palette[11])
  term.brightblue =	make_color_24(palette[12])
  term.brightmagenta =	make_color_24(palette[13])
  term.brightcyan =	make_color_24(palette[14])
  term.brightwhite =	make_color_24(palette[15])
  term.fzf_colors = " --no-bold --color=hl:"..palette[6]..
                    ",selected-hl:"..palette[3]..
                    ",current-bg:"..palette[8]..
                    ",gutter:"..palette[8]..
                    ",hl+:"..palette[14]..
                    ":reverse"..
                    ",query:"..palette[14]..
                    ",info:"..palette[11]..
                    ",disabled:"..palette[13]..
                    ",scrollbar:"..palette[15]..
                    ",pointer:"..palette[14]..
                    " "
  -- term.fzf_colors = " --no-color "
else
  term.black = "\x1b[30m"             -- 0
  term.red = "\x1b[31m"               -- 1
  term.green = "\x1b[32m"             -- 2
  term.yellow = "\x1b[33m"            -- 3
  term.blue = "\x1b[34m"              -- 4
  term.magenta = "\x1b[35m"           -- 5
  term.cyan = "\x1b[36m"              -- 6
  term.white = "\x1b[37m"             -- 7
  term.brightblack = "\x1b[90m"       -- 8
  term.brightred = "\x1b[91m"         -- 9
  term.brightgreen = "\x1b[92m"       -- 10
  term.brightyellow = "\x1b[93m"      -- 11
  term.brightblue = "\x1b[94m"        -- 12
  term.brightmagenta = "\x1b[95m"     -- 13
  term.brightcyan = "\x1b[96m"        -- 14
  term.brightwhite = "\x1b[97m"       -- 15
  term.fzf_colors = " --color=16,hl:3,selected-hl:3,gutter:0,hl+:11:reverse,query:11,info:14,disabled:13,scrollbar:15,pointer:11 "
end


return term
