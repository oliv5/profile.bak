if exists('loaded_wndmgr')
  finish
endif
let loaded_wndmgr = 1

" Plugins which open window
if !exists('g:wndmgr_pluginList')
  let g:wndmgr_pluginList = [
      \ "-MiniBufExplorer-",
      \ "_NERD_tree_",
      \ "__Tag_List__",
      \ "Source_Explorer",
      \ "\.vimprojects",
  \ ]
endif

" Get the edit window number, avoiding plugins windows
function! g:wndmgr_GetEditWnd(start)
  for idx in (range(a:start, winnr("$")))
    for item in g:wndmgr_pluginList
      "echo "[Wndmgr_GetEditWnd]" bufname(winbufnr(idx)) "==" item
      "if bufname(winbufnr(idx)) ==# item
      if !empty(matchstr(bufname(winbufnr(idx)), item))
        let item = -1
        break
      endif
    endfor
    if item != -1
      "echo "[Wndmgr_GetEditWnd] Selected window:" bufname(winbufnr(idx))
      return idx
    endif
  endfor
  return -1
endfunction

" Jump to the edit window, avoiding plugins windows
function! g:wndmgr_JumpEditWnd()
  let idx = 0
  while idx >= 0
    " Get the edit window number
    let idx = g:wndmgr_GetEditWnd(idx+1)
    if idx >= 0
      " Jump to that window
      silent! exec idx . "wincmd w"
      " Stop if modifiable, otherwise search again from next window
      if &modifiable == 1
        return
      endif
    endif
  endwhile
  " not found: split
  silent! exec ":split"
endfunction

" Update SrcExplorer window
function! g:wndmgr_UpdateSrcExplWindow()
  let l:source_explorer_winnr = 0
  try
    " For Named Buffer Version
    let l:source_explorer_winnr = g:SrcExpl_GetWin()
  catch
  finally
    " For Preview Window Version
    if l:source_explorer_winnr == 0
      let l:i = 1
      while 1
        if bufname(winbufnr(l:i)) ==# s:source_explorer_title
              \ || getwinvar(l:i, '&previewwindow')
          let l:source_explorer_winnr = l:i
          break
        endif
        let l:i += 1
        if l:i > winnr("$")
          break
        endif
      endwhile
    endif
    if l:source_explorer_winnr > 0
      silent! exe l:source_explorer_winnr . "wincmd " . "w"
      silent! exe "wincmd " . "J"
      silent! exe g:SrcExpl_winHeight . " wincmd " . "_"
    endif
    let l:rtn = g:wndmgr_GetEditWnd(0)
    if l:rtn < 0
      return
    endif
    silent! exe l:rtn . "wincmd w"
  endtry
endfunction

" Find and resize/locate window
function! g:wndmgr_ExecOnWindow(title, cmd, args)
  for l:idx in (range(1, winnr("$")))
    if !empty(matchstr(bufname(winbufnr(l:idx)), a:title))
      silent! exe l:idx . "wincmd " . "w"
      silent! exe a:args . "wincmd " . a:cmd
      "echom "Execute " . a:title . " " . winnr() . ": " . a:args. " wincmd " . a:cmd
      break
    endif
  endfor
endfunction
