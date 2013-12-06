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

" Check if this is a plugin windows
function! g:wndmgr_IsPluginWnd(wndidx)
    let name = bufname(winbufnr(a:wndidx))
    " Parse the list of plugins
    for item in g:wndmgr_pluginList
        "if name ==# item
        if !empty(matchstr(name, item))
            return 1
        endif
    endfor
    " Not a plugin window
    return 0
endfunction

" Check if this is an edit window (non-plugin & modifiable)
function! g:wndmgr_JumpEditWndById(wndidx)
  if a:wndidx<winnr('$') && !g:wndmgr_IsPluginWnd(a:wndidx)
    " Jump to that window
    silent! exec a:wndidx . "wincmd w"
    " Check if modifiable & not quickfix
    if &modifiable && &buftype!=#"quickfix"
      "echo "[wndmgr_IsEditWnd]" bufname(winbufnr(a:wndidx)) "(" . a:wndidx . ")"
      return 1
    else
      " Jump back
      silent! "wincmd W"
    endif
  endif
  return 0
endfunction

" Jump to the edit window, avoiding plugins windows
function! g:wndmgr_JumpEditWnd()
  " Check the previous window is editable
  if g:wndmgr_JumpEditWndById(winnr("#"))
    return
  endif
  " Loop through all windows
  for wndidx in (range(1, winnr("$")))
    if g:wndmgr_JumpEditWndById(wndidx)
      return
    endif
  endfor
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
