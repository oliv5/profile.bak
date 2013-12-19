if exists('loaded_wndmgr_jmp')
  finish
endif
let loaded_wndmgr_jmp = 1

" Plugins which open windows
if !exists('g:wndmgr_pluginList')
  let g:wndmgr_pluginList = []
endif

" Create an empty wnd list
if !exists('g:wndmgr_wndList')
  let g:wndmgr_wndList = []
endif

" Set wnd list max size
let g:wndmgr_wndListMaxSize = 5


"""""""""""

" Window manager autocommands
" Then we set the routine function when the event happens
augroup wndmgr_autoCmd
    autocmd!
    au! WinEnter * nested call g:wndmgr_PushWndList()
augroup end


"""""""""""

" Avoid other plugin windows
" From plugin Source Explorer
function! g:wndmgr_AvoidPluginWnd()
    " Filter Quickfix window
    if &buftype ==# "quickfix"
        return -1
    endif
    " Filter preview window
    "if getwinvar(winnr("%"), "&pvw") == 1
    if &previewwindow
        return -3
    endif
    " Search the bufname in the plugin list (pattern matching, not "==#")
    "if len(bufname("%")) && match(g:wndmgr_pluginList, bufname("%"))!=-1
    "    return -2
    "endif
    " Search the bufname in the plugin list (pattern matching, not "==#")
    let buffer = bufname("%")
    if len(buffer)
        for pattern in g:wndmgr_pluginList
            if match(buffer, pattern)!=-1
                return -2
            endif
        endfor
    endif
    " Not a plugin
    return 0
endfunction


" Set a new mark for back to the previous position
function! g:wndmgr_PushWndList()
    " Avoid pushing the same window twice
    if len(g:wndmgr_wndList) && g:wndmgr_wndList[-1]==winnr()
        return
    endif
    " Avoid plugin windows
    if g:wndmgr_AvoidPluginWnd()
        return
    endif
    " Push current window onto the list
    call add(g:wndmgr_wndList, winnr())
    " Limit the list size
    if len(g:wndmgr_wndList) > g:wndmgr_wndListMaxSize
        call remove(g:wndmgr_wndList, 0)
    endif
endfunction


" Pop few windows, returns the first one (or the current one when empty)
function! g:wndmgr_PopWndList(num_wnd)
    " Pop & return few windows
    if len(g:wndmgr_wndList) >= a:num_wnd
        return remove(g:wndmgr_wndList, -a:num_wnd, -1)[0]
    endif
    " Not enough windows, don't modify the list
    " Return the current window
    return winnr()
endfunction


" Jump to the edit window, avoiding plugins windows
function! g:wndmgr_JumpEditWnd()
    let num_wnd = 1
    if len(g:wndmgr_wndList) && g:wndmgr_wndList[-1]==winnr()
        let num_wnd = 2
    endif
    silent! exe g:wndmgr_PopWndList(num_wnd) "wincmd w"
endfunction
