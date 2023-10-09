# `nvim-fzf` commands for Windows

Environment variables I use by default:

`BAT_STYLE=numbers,changes`

`FZF_DEFAULT_OPTS=--no-mouse --layout=default --preview-window=hidden:border-left --margin=0 --padding=1 --pointer=⏵ --marker=+ --info=inline --tabstop=4 --no-bold --bind=f2:toggle-preview,f3:toggle-preview-wrap,shift-down:preview-down,shift-up:preview-up,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-f:page-down,ctrl-b:page-up,ctrl-a:toggle-all,ctrl-l:clear-query,ctrl-s:toggle-sort`

`FZF_DEFAULT_COMMAND=rg --files --no-ignore --hidden --follow --glob "!.git/*" --color=auto`

`FZF_PREVIEW_COMMAND=bat --decorations=always --paging=never --italic-text=never --color=always --theme=ansi --wrap=never`

## How to use

I map commands to keyboard shortcuts directly:

```lua
local map = vim.api.nvim_set_keymap
local options = { noremap = true, silent = true }
local common_fzf_opts = '{ border = false, relative = "editor", width=280, noautocmd = true }'
map('n','<C-d>f', '<CMD>lua require("fzf-commands-windows").files({ fzf = function(contents, options) return require("fzf").fzf(contents, options, ' .. common_fzf_opts ..') end })<CR>', options)
```

### Universal Ctags settings for `Ctags` command

Use `--excmd=combine` to add line numbers to `tags` file.

## TODO

1. [x] Files
   - [x] `CTRL-S` to open file in a split
   - [x] `CTRL-V` to open file in a vertical split
   - [x] `CTRL-T` to open file in a new tab

2. [x] Marks
   - [x] `CTRL-Q` to delete mark(s)
   - [x] `CTRL-S` to open mark(s) location in a split
   - [x] `CTRL-V` to open mark(s) location in a vertical split
   - [x] `CTRL-T` to open mark(s) location in a new tab

3. [x] Registers
   - [x] `CTRL-Q` to delete register(s)
   - [x] `CTRL-P` to paste register(s) before
   - [x] `ENTER` to paste register(s)

4. [x] Buffers
   - [x] `ENTER` to go to ONE single selected buffer (hidden opens in curent window, active moves focus to tab and window of the buffer)
   - [x] `CTRL-Q` to delete buffer(s)
   - [x] `CTRL-S` to open buffer(s) in a split
   - [x] `CTRL-V` to open buffer(s) in a vertical split
   - [x] `CTRL-T` to open buffer(s) in a new tab

5. [x] BLines = lines from current buffer
   - [x] Multiple selections go to quickfix list on `ENTER` and location list on `ALT-ENTER`

6. [x] Lines = lines from all buffers
   - [ ] `CTRL-S` to open buffer in a split and go to this line
   - [ ] `CTRL-V` to open buffer in a vertical split and go to this line
   - [ ] `CTRL-T` to open buffer in a new tab (get file name from buffer, open in new tab) go to this line
   - [x] Multiple selections go to quickfix list on `ENTER`

7. [x] Filetypes

8. [x] Rg
   - [x] Push to QuickFix list on `Enter` if multiple items selected
   - [x] `:Rg` command to search by Ripgrep regex

9. [x] UGrep
   - [x] Push to QuickFix list on `Enter` if multiple items selected
   - [x] `:Ug` command to search by uGrep regex

10. [x] GDiff = find all the Git-changes for current file
    - [x] Open chosen commit file in a vertical split with diff on (if you want something from it to your current file)

11. [x] Ctags: Show all tags from a current `tags` file and go to each tags
        location. Tags format is defined in my config and includes lines numbers
        to parse

12. [x] Commands History

13. [x] Search History

14. [x] Directories
    - `ENTER` to change current tab directory,
    - `CTRL-L` (local) to change current window directory,
    - `CTRL-G` (global) to change directory of Neovim instance

15. [x] PGrep = PowerGrep functionality for searching unique entries by
    regular expression. Usage: `:PGrep <regex>`

16. [ ] LSP = Work in Progress, only Diagnostics available for now
