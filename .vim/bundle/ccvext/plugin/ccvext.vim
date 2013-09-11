" Name:     ccvext.vim (ctags and cscope vim extends script)
" Brief:    Usefull tools reading code or coding
" Version:  4.5.0
" Date:     2011/06/10 12:55:57
" Author:   Chen Zuopeng (EN: Daniel Chen)
" Email:    chenzuopeng@gmail.com
"
" License:  Public domain, no restrictions whatsoever
"
" Copyright:Copyright (C) 2009-2010 Chen Zuopeng {{{
"           Permission is hereby granted to use and distribute this code,
"           with or without modifications, provided that this copyright
"           notice is copied with it. Like anything else that's free,
"           ccvext.vim is provided *as is* and comes with no
"           warranty of any kind, either expressed or implied. In no
"           event will the copyright holder be liable for any damages
"           resulting from the use of this software.
"           }}}
" Usage:    {{{ This file should reside in the plugin directory and be
"           automatically sourced.
"             Command: "EnQuickSnippet" - Start source snippet (a better way to use ctags)
"             Command: "DiQuickSnippet" - Stop source snippet (a better way to use ctags)
"           }}}
" UPDATE:{{{
"           OLA 4.7.1
"             Cleanup & remove useless functions
"           4.7.0
"             Descript:
"               - Fix the problem about permission on Unix like system.
"           4.6.0
"             Descript:
"               - Fix the problem the multi cscope connection problem about that connection then
"                 disconnection for few times the connection order will confused.
"           4.5.0
"             Descript:
"               - Fix the problem when ccvext work with script bufexplorer.vim
"           4.4.0
"             Descript:
"               - Add C# source code supported. (Recently I am working with it)
"               - Fix the problem: Sometimes double click the soruce snippet window will cause a dead loop.
"             TODO:
"               - Cscope database list is not work perfect.
"           4.3.0
"             Descript:
"               - When tags file and cscope file not exist, auto remove it from config list.
"           4.2.0
"       Descript:
"         - Don't search from tags when the text's lenght is equal to 1
"         - Don't search from tags when the text data is c/c++ key word.
"             BugFix:
"               - Fix the problem about double click in the main source window.
"           4.1.0
"       Descript:
"         - Modify tip window's info when tags searched not found.
"           4.0.0
"             Descript:
"               - Rename commands name
"               - Auto update source snippet window
"           3.0.1
"             Fix Bugs:
"               - correct the cursor position when jump global value in snippet window
"           3.0.0
"             New Feature:
"               - Virtual tag is support, a better way to use ctags. CTRL_] is
"                 over writen.
"
"             Fix Bugs:
"               - Open and close config (<Leader>sc) window vim not focuses the old window
"                 when multi windows are opened.
"               - Fix a bug about the tips.
"           2.0.0
"             Rewrite script the previous is JumpInCode.vim
"        }}}
"-------------------------------------------CCVEXT-----------------------------------------
"

" Version check
if exists("g:ccvext_version")
  finish
endif
let g:ccvext_version = "4.7.0"

" Check for Vim version 700 or greater {{{
if v:version < 700
  echo "Sorry, ccvext" . g:ccvext_version. "\nONLY runs with Vim 7.0 and greater."
  finish
endif
"}}}

" OLA++ Options {{{
if !exists("g:ccvext_WndHeight")
  let g:ccvext_WndHeight = 8
endif
if !exists("g:ccvext_autostart")
  let g:ccvext_autostart = 0
endif
"}}}

"Global value declarations {{{
let s:functions = {'_command':{}}
"let s:symbs_dir_name = '.symbs'
"}}}

"Initialization local variable platform independence {{{
let s:platform_inde = {
  \'win32':{
      \'slash':'\', 'HOME':'\.symbs', 'list_f':'\.symbs\.list', 'env_f':'\.symbs\.env'
      \},
  \'unix':{
      \'slash':'/', 'HOME':$HOME . '/.symbs', 'list_f':$HOME . '/.symbs/.l', 'env_f':$HOME . '/.symbs/.evn'
      \},
  \'setting':{
      \'tags_l':['./tags']
      \},
  \'tmp_variable':0
  \}
"}}}

"Platform check {{{
if has ('win32')
  let s:platform = 'win32'
else
  let s:platform = 'unix'
endif
"}}}

"support postfix list {{{
let s:postfix = ['"*.java"', '"*.h"', '"*.c"', '"*.hpp"', '"*.cpp"', '"*.cc"', '*.cs', '*.js']
"}}}

" default colors/groups {{{
  hi default_hi_color ctermbg=Cyan ctermfg=Black guibg=#8CCBEA guifg=Black
"}}}

"Check software environment {{{
if !executable ('ctags')
  echomsg 'Taglist: Exuberant ctags (http://ctags.sf.net) ' .
          \ 'not found in PATH. Plugin is not full loaded.'
  finish
endif

if !executable ('cscope')
  echomsg 'cscope: cscope (http://cscope.sourceforge.net/) ' .
          \ 'not found in PATH. Plugin is not full loaded.'
  finish
endif
"}}}

"---------------------------------------CCVEXT EXTEND-----------------------------------------

"Enable quick source snippet{{{
function! EnQuickSnippet ()
  "ctags is necessary
  if !executable ('ctags')
    echomsg 'ctags error(ctags is necessary): ' .
                \'Exuberant ctags (http://ctags.sf.net) ' .
                \ 'not found in PATH. Plugin is not full loaded.'
    return 'false'
  endif

  call MarkWindow ('main_source_window_mark')

  :let s:update_time = 800
  :exe "set updatetime=" . string(s:update_time)

  :au! CursorHold * nested call AutoTagTrace ()
  ":au! WinEnter * call AutoRemoveBufferMap ()
endfunction
"}}}

"Disable quick source snippet {{{
function! DiQuickSnippet ()
    :au! CursorHold
  :au! WinEnter
    ":call GoToMarkedWindow (1, 'main_source_window_mark')
    "exec 'silent! wincmd o'
    "close source snippet list window
    if FindMarkedWindow (1, 'source_snippet_list_wnd') != 0
        if GoToMarkedWindow (1, 'source_snippet_list_wnd') == 'true'
      :close!
    endif
    endif
    "close source snippet window
    if FindMarkedWindow (1, 'source_snippet_wnd') != 0
        if GoToMarkedWindow (1, 'source_snippet_wnd') == 'true'
      :close!
    endif
    endif

    call GoToMarkedWindow (1, 'main_source_window_mark')
    call UnmarkWindow ()
endfunction
"}}}

"Cscope and ctags popup menu {{{
function! CscopeCtagsMenu ()
  call OtherPluginDetect ()

  if has ("win32") || has ("win64")
        \ && exists (":tearoff")
    :tearoff Plugin.CCVimExt
  else
    echo "Command is not supported in this version of vim."
  endif
endfunction
"}}}

"Temp close snipped window and list window {{{
function! CloseSnippedWndAndListWndOnce ()
    if FindMarkedWindow (1, 'source_snippet_list_wnd') != 0
        if GoToMarkedWindow (1, 'source_snippet_list_wnd') == 'true'
      :close!
    endif
    endif
    "close source snippet window
    if FindMarkedWindow (1, 'source_snippet_wnd') != 0
        if GoToMarkedWindow (1, 'source_snippet_wnd') == 'true'
      :close!
    endif
    endif

    call GoToMarkedWindow (1, 'main_source_window_mark')
endfunction
"}}}

"Trace tags {{{
function! TagTrace (tag_s)
    "ctags is necessary
    if !executable ('ctags')
        return 'false'
    endif

    if a:tag_s == '' || a:tag_s == ':' || a:tag_s == ';'
        \|| a:tag_s == 'int'
        \|| a:tag_s == 'float'
        \|| a:tag_s == 'double'
        \|| a:tag_s == 'unsigned'
        \|| a:tag_s == 'return'
        \|| a:tag_s == 'if'
        \|| a:tag_s == 'else'
        \|| a:tag_s == 'case'
        \|| a:tag_s == 'break'
        \|| strlen (a:tag_s) == 1
        return 'false'
    endif
    "save current tag for hight light
    let s:current_tag = a:tag_s

    let s:src_snippet_list_wnd = 'source_snippet_list_wnd'

    "If the list window is open
    let l:marked_wnd_num = FindMarkedWindow (1, 'source_snippet_list_wnd')
    if l:marked_wnd_num == 0
        "open s:src_snippet_list_wnd
        exec 'silent! botright ' . g:ccvext_WndHeight . 'split ' . s:src_snippet_list_wnd
        call MarkWindow ('source_snippet_list_wnd')
    endif

    "let l:escaped_tag = escape(escape(escape(escape(a:tag_s, '*'), '"'), '~'), ':')
    "let s:tags_l = taglist (l:escaped_tag)
    let s:tags_l = taglist (escape(a:tag_s, '~'))

    "jump to s:src_snippet_list_wnd
    :call GoToMarkedWindow (1, 'source_snippet_list_wnd')

    "tags data list
    let l:put_l  = []

    "push tags data to list
    if empty (s:tags_l)
      "call add (l:put_l, 'No symbs found in tags: ' . &tags)
      let l:tag_list_file = tagfiles ()
      if empty (l:tag_list_file)
        call add (l:put_l, "Check time: " . strftime("%H:%M:%S"))
        call add (l:put_l, 'Tags is not set, please call :SyncSource or :SymbsConfig first')
      else
        call add (l:put_l, "Check time: " . strftime("%H:%M:%S") . " No symbs found in tags:")
        for l:single in l:tag_list_file
          call add (l:put_l, l:single)
        endfor
      endif
    else
      for l:idx in s:tags_l
        call add (l:put_l, l:idx['filename'])
        "call add (l:put_l, fnamemodify(l:idx['filename'],":p:~:."))
      endfor
    endif

    "write data to buffer
    if winnr () == bufwinnr(s:src_snippet_list_wnd)
      setlocal modifiable
      set number
      1,$d _
      0put = l:put_l

      " Mark the buffer as scratch
      setlocal buftype=nofile
      setlocal bufhidden=delete
      setlocal noswapfile
      setlocal nowrap
      setlocal nobuflisted
      normal!  gg
      setlocal nomodifiable
    endif

    " Create a mapping to jump to the file
    nmap <buffer><silent><CR>  :call SourceSnippet()<CR>
    nmap <buffer><2-LeftMouse> :call SourceSnippet()<CR>

    if empty (s:tags_l)
      "do nothing
    else
      call SourceSnippet ()
    endif
    "move cursor to previous window
    :call GoToMarkedWindow (1, 'main_source_window_mark')
    return 'true'
endfunction
"}}}

"Auto trace tags {{{
function! AutoTagTrace ()
  if FindMarkedWindow (1, 'main_source_window_mark') == 0
    "call DiQuickSnippet ()
    "echo "Auto close quick snippet window, because the main source window is closed."
    "return
    call EnQuickSnippet ()
  endif
  if winnr () == FindMarkedWindow (1, 'main_source_window_mark')
    for l:filetype in s:postfix
      if matchstr (l:filetype, &ft) != "" && &ft != ""
        call TagTrace (expand('<cfile>'))
        break
      endif
    endfor
    return
  endif
    "forcus on other window
    "if winnr () == FindMarkedWindow (1, 'main_source_window_mark')
  " call TagTrace (expand('<cfile>'))
    "    return
    "endif
    if winnr () == FindMarkedWindow (1, 'source_snippet_list_wnd')
        if empty (s:tags_l)
        else
            call SourceSnippet ()
        endif
        return
    endif
endfunction
"}}}

"Remove source snippet window's property {{{
function! AutoRemoveBufferMap ()
  "if winnr () == FindMarkedWindow (1, "main_source_window_mark")
  " for l:filetype in s:postfix
  "   if matchstr (l:filetype, &ft) != -1
  "     "nmapclear <buffer>
  "     nmapclear <buffer>
  "   endif
  " endfor
  "endif
  "if winnr () == FindMarkedWindow (1, "source_snippet_wnd")
  " call SetSnippetWndMap ()
  "endif
endfunction
"}}}

"Set snippet window buffer map {{{
function! SetSnippetWndMap ()
    nmap <buffer><Enter> :call <SID>MagicFunc () <CR><CR>
    nmap <buffer><2-LeftMouse> :call <SID>MagicFunc() <CR><CR>
endfunction
"}}}

"Dev log output {{{
function! DevLogOutput (txt)
  echohl ErrorMsg
    echo "a:txt"
  echohl None
endfunction
"}}}

"Source Snippet {{{
function! SourceSnippet()
    "jump to s:src_snippet_list_wnd window
    "exec 'silent!' . bufwinnr (s:src_snippet_list_wnd) . ' wincmd w'
    "make sure cursor is in s:src_snippet_list_wnd

    if winnr () != bufwinnr(s:src_snippet_list_wnd)
        "Error window status
        call DevLogOutput ('SystemError:', 'Error window status')
        return
    endif

    if -1 == bufwinnr(s:src_snippet_list_wnd)
        "Unhandled error occur.
        call DevLogOutput ('SystemError:', 'Unhandled error occur')
        return
    endif

    let l:new_line = getline('.')

    if FindMarkedWindow (1, 'source_snippet_wnd') == 0
        "open s:src_snippet_list_wnd
        exec 'vertical abo split' . ' ' . l:new_line
        call MarkWindow ('source_snippet_wnd')
    else
        call GoToMarkedWindow (1, 'source_snippet_wnd')
        "close!
        "exec 'vertical abo split' . ' ' . l:new_line
        "call MarkWindow ('source_snippet_wnd')
        exec 'e!' . ' ' . l:new_line
    endif

    if winnr () == FindMarkedWindow (1, 'source_snippet_wnd')
    "setlocal buftype=nofile
    "setlocal bufhidden=delete
    "setlocal noswapfile
    "setlocal nowrap
    "setlocal nobuflisted
    "setlocal nomodifiable
    endif

    call SetSnippetWndMap ()
    set number

    let l:cmd_s = 'v_null'
    for l:idx in s:tags_l
        if l:idx['filename'] == l:new_line
            let l:cmd_s = matchstr(l:idx['cmd'], '\^.*\$')
            if l:cmd_s == ''
                let l:cmd_s = matchstr(l:idx['name'], '.*')
            endif
        endif
    endfor
    let l:cmd_s = escape(escape(escape(escape(l:cmd_s, '*'), '"'), '~'), ':')

    "let l:cmd_s = '\\<' . l:cmd_s . '\\>'
    "echo l:cmd_s
    call search (l:cmd_s, 'w')

    normal zt
    redraw
    exe "windo syntax clear default_hi_color"
    exe "syntax match default_hi_color" . " '" . escape (s:current_tag, "~") . "' " . "containedin=.*"

    "go back to list window
    exec 'silent! ' . bufwinnr(s:src_snippet_list_wnd) . 'wincmd w'
endfunction
"}}}

"Magic Function {{{
fu! <SID>MagicFunc ()
    if winnr () == FindMarkedWindow (1, 'main_source_window_mark')
    nmapclear <buffer>
  else
    let l:bufnr = bufnr ('%')
    let l:current_line_nu = line ('.')
    call GoToMarkedWindow (1, 'main_source_window_mark')
    exec 'b' . ' ' . l:bufnr
    exec ':' . l:current_line_nu
    "nmapclear <buffer>
    endif
endf
"}}}

"External Function: GoToLine {{{
function! GoToLine(mainbuffer)
   let linenumber = expand("<cword>")
   silent bd!
   silent execute "buffer" a:mainbuffer
   silent execute ":"linenumber
   nunmap <Enter>
endfunction
"command -nargs=1 GoToLine :call GoToLine(<f-args>)
"}}}

"External Function: GrepToBuffer {{{
function! GrepToBuffer(pattern)
   let mainbuffer = bufnr("%")
   silent %yank g

   enew
   silent put! g
   execute "%!egrep -n" a:pattern "| cut -b1-80 | sed 's/:/ /'"
   silent 1s/^/\="# Press Enter on a line to view it\n"/
   silent :2

   silent execute "nmap <Enter> 0:silent GoToLine" mainbuffer "<Enter>"
   silent nmap <C-G> <C-O>:bd!<Enter>
endfunction

"command -nargs=+ Grep :call GrepToBuffer(<q-args>)
"}}}

"Mark window {{{
function! MarkWindow (mark_desc)
    let w:wnd_mark = a:mark_desc
endfunction
"}}}

"Unmark window {{{
function! UnmarkWindow ()
    let w:wnd_mark = ''
endfunction
"}}}

"Find marked window {{{
function! FindMarkedWindow (page_idx, mark_desc)
    let l:win_count = tabpagewinnr (a:page_idx, '$')
    for l:idx in range (1, l:win_count)
        let l:tmp = getwinvar(l:idx, 'wnd_mark')
        if l:tmp == a:mark_desc
            return l:idx
        endif
    endfor
    return 0
endfunction
"}}}

"Go go marked window {{{
function! GoToMarkedWindow (page_idx, mark_desc)
    let l:marked_wnd_num = FindMarkedWindow (a:page_idx, a:mark_desc)
  if l:marked_wnd_num != 0
    exec 'silent! ' . string(l:marked_wnd_num) . 'wincmd w'
  else
    return 'false'
  endif
  return 'true'
endfunction
"}}}

"Command setting {{{
if !exists(':CCVEEnQuickSnippet')
  command! -nargs=0 CCVEenQuickSnippet :call EnQuickSnippet ()
endif
if !exists(':CCVEDiQuickSnippet')
  command! -nargs=0 CCVEdiQuickSnippet :call DiQuickSnippet ()
endif
if g:ccvext_autostart == 1
  CCVEenQuickSnippet
endif
"}}}

"
" vim600:fdm=marker:fdc=4:cms=\ "\ %s:
