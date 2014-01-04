if exists('loaded_wndmgr_exec')
  finish
endif
let loaded_wndmgr_exec = 1


" Execute a command in a window identified by its buffer
function! g:wndmgr_ExecWnd(title, cmd, args)
    let idx = bufwinnr(a:title)
    if idx>0
        silent! exe idx "wincmd w"
        silent! exe a:args "wincmd" a:cmd
        "echom "Execute" a:title idx ":" a:args "wincmd" a:cmd
    endif
endfunction


" Update SrcExplorer window
function! g:wndmgr_UpdateSrcExplWindow()
    call g:wndmgr_ExecWnd("Source_Explorer","J","")
    call g:wndmgr_ExecWnd("Source_Explorer","_",g:SrcExpl_winHeight)
endfunction
