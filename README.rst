# `nvim-fzf` commands for Windows

Environment variables I use by default:

``BAT_STYLE=numbers,changes``

``FZF_DEFAULT_OPTS=--no-mouse --layout=default --preview-window=hidden:border-left --margin=0 --padding=1 --pointer=⏵ --marker=+ --info=inline --tabstop=4 --no-bold --bind=f2:toggle-preview,f3:toggle-preview-wrap,shift-down:preview-down,shift-up:preview-up,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-f:page-down,ctrl-b:page-up,ctrl-a:toggle-all,ctrl-l:clear-query,ctrl-s:toggle-sort``

``FZF_DEFAULT_COMMAND=rg --files --no-ignore --hidden --follow --glob "!.git/*" --color=auto``

``FZF_PREVIEW_COMMAND=bat --decorations=always --paging=never --italic-text=never --color=always --theme=ansi --wrap=never``

## TODO

* [+] Files
* [±] Marks
* [ ] Buffers
* [ ] BufferLines
* [ ] BufferLinesAll
