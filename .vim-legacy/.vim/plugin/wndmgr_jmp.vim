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
let g:wndmgr_wndListMaxSize = 10


"""""""""""

" Window manager autocommands
augroup wndmgr_autoCmd
    autocmd!
    au! WinEnter * nested call g:wndmgr_PushWndList()
augroup end


"""""""""""

" Check if this is a plugin windows
function! g:wndmgr_IsPluginWnd(wndidx)
    " Not a Quickfix window
    if getwinvar(a:wndidx, "&buftype") ==# "quickfix"
        return -1
    endif
    " Not a preview window
    if getwinvar(a:wndidx, "&pvw")
        return -3
    endif
    " Search the bufname in the plugin list (pattern matching, not "==#")
    "if len(bufname("%")) && match(g:wndmgr_pluginList, bufname("%"))!=-1
    "    return -2
    "endif
    " Search the bufname in the plugin list (pattern matching, not "==#")
    let buffer = bufname(winbufnr(a:wndidx))
    for pattern in g:wndmgr_pluginList
        if match(buffer, pattern)!=-1
            return -2
        endif
    endfor
    " Not a plugin window
    return 0
endfunction


" Avoid other plugin windows
" From plugin Source Explorer
function! g:wndmgr_AvoidPluginWnd()
    return g:wndmgr_IsPluginWnd(winnr())
endfunction


" Empty window list
function! g:wndmgr_ClearWndList()
    let g:wndmgr_wndList = []
endfunction


" Clean window list, remove plugin windows
function! g:wndmgr_CleanWndList()
    call filter(g:wndmgr_wndList, '!g:wndmgr_IsPluginWnd(v:val)')
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
        "call g:wndmgr_CleanWndList()
        call remove(g:wndmgr_wndList, 0)
    endif
endfunction


" Pop few windows, returns the first one (or the current one when empty)
function! g:wndmgr_PopWndList()
    " Pop & return non-plugin windows
    while !empty(g:wndmgr_wndList)
        let window = remove(g:wndmgr_wndList, -1, -1)[0]
        if !g:wndmgr_IsPluginWnd(window)
            return window
        endif
    endwhile
    " Not enough windows, return the first non-plugin window
    for window in (range(1, winnr("$")))
        if !g:wndmgr_IsPluginWnd(window)
            return window
        endif
    endfor
    " Found nothing, return the current window
    echo "Found no non-plugin window candidate"
    return winnr()
endfunction


" Jump to the edit window, avoiding plugins windows
function! g:wndmgr_JumpEditWnd()
    "if len(g:wndmgr_wndList) && g:wndmgr_wndList[-1]==winnr()
    "    call remove(g:wndmgr_wndList, -1, -1)
    "endif
    exe g:wndmgr_PopWndList() "wincmd w"
endfunction
