" Create an empty wnd list
if !exists('g:wndmgr_wndList')
  let g:wndmgr_wndList = []
endif

" Set wnd list max size
let g:wndmgr_wndListMaxSize = 5

" Window manager autocommands
" Then we set the routine function when the event happens
augroup wndmgr_autoCmd
    autocmd!
    au! WinEnter * nested call g:wndmgr_PushWndList()
augroup end

" Avoid other plugin windows
" From plugin Source Explorer
function! g:wndmgr_AvoidPluginWnd()
    " Search the bufname in the plugin list (pattern matching, not "==#")
    if match(g:wndmgr_pluginList, bufname("%"))
        return -1
    endif
    " Also filter the Quickfix window
    if &buftype ==# "quickfix"
        return -1
    endif
    " Safe
    return 0
endfunction


" Set a new mark for back to the previous position
function! g:wndmgr_PushWndList()
    " Push a new mark into the list when window is valid
    if !g:wndmgr_AvoidPluginWnd()
        call add(g:wndmgr_wndList, winnr())
        " Limit list size
        if len(g:wndmgr_wndList) > g:wndmgr_wndListMaxSize
            call remove(g:wndmgr_wndList, 0)
        endif
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
    exe g:wndmgr_PopWndList(2) "wincmd w"
endfunction


finish







" Create an empty Wnd list
if !exists('g:wndmgr_wndList')
  let g:wndmgr_wndList = []
endif
" Wnd list max size
let g:wndmgr_wndListMaxSize = 5

" Window manager autocommands
" Then we set the routine function when the event happens
augroup wndmgr_autoCmd
    autocmd!
    au! WinEnter * nested call g:wndmgr_PushWndList()
augroup end

" Avoid other plugin windows
" From plugin Source Explorer
function! g:wndmgr_AvoidPluginWnd()
    " Search the bufname in the plugin list (pattern matching, not "==#")
    if match(g:wndmgr_pluginList, bufname("%"))
        return -1
    endif
    " Also filter the Quickfix window
    if &buftype ==# "quickfix"
        return -1
    endif
    " Safe
    return 0
endfunction


" Set a new mark for back to the previous position
function! g:wndmgr_PushWndList()
    " Push a new mark into the list when window is valid
    if !g:wndmgr_AvoidPluginWnd()
        call add(g:wndmgr_wndList, winnr())
        " Limit list size
        if len(g:wndmgr_wndList) > g:wndmgr_wndListMaxSize
            call remove(g:wndmgr_wndList, 0)
        endif
        return 0
    endif
    return -1
endfunction

" Pop few windows, returns the first one (or the current one when empty)
function! g:wndmgr_PopWndList(num_wnd)
    if len(g:wndmgr_wndList) >= a:num_wnd
        " Pop & return some windows
        return remove(g:wndmgr_wndList, -a:num_wnd, -1)[0]
    endif
    " Nothing to remove, tell we are in the current window
    return winnr()
endfunction

" Jump to the edit window, avoiding plugins windows
function! g:wndmgr_JumpEditWnd()
    let num_wnd = 1
    " Remove the current window from the list
    " If we are into it
    if winnr() == g:wndmgr_wndList[-1]
      let num_wnd = num_wnd + 1
    endif
    "echo g:wndmgr_PopWndList(num_wnd)
    exe g:wndmgr_PopWndList(num_wnd) "wincmd w"
    "echo g:wndmgr_wndList
    "remove(g:wndmgr_wndList, -1)
endfunction







finish




" Check if this is a plugin windows
function! g:wndmgr_IsPluginWnd_2(wndidx)
  for plugin in g:wndmgr_pluginList
    "if bufname(winbufnr(a:wndidx)) ==# plugin
    if !empty(matchstr(bufname(winbufnr(a:wndidx)), plugin))
      "echo "[wndmgr_IsPluginWnd]" bufname(winbufnr(a:wndidx))
      return 1
    endif
  endfor
  return 0
endfunction

" Check if this is a plugin windows
function! g:wndmgr_IsPluginWnd(wndidx)
    let name = bufname(winbufnr(a:wndidx))
    " Parse the list of plugins
    for item in g:wndmgr_pluginList
        if name ==# item
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

finish
























" *******************************************************
" * Omnifunc
" *******************************************************
" Enable
"filetype plugin on
"set omnifunc=syntaxcomplete#Complete
" Autocommands
"autocmd FileType python set omnifunc=pythoncomplete#Complete
"autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
"autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
"autocmd FileType css set omnifunc=csscomplete#CompleteCSS
"autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
"autocmd FileType php set omnifunc=phpcomplete#CompletePHP
"autocmd FileType c set omnifunc=ccomplete#Complete
" Map
"imap <C-Space> <C-X><C-O>


" *******************************************************
" * Omnicpp
" *******************************************************
" Enable
set nocp
filetype plugin on
" Map
imap <C-Space> <C-X><C-O>

let OmniCpp_NamespaceSearch = 1
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_ShowAccess = 1
let OmniCpp_MayCompleteDot = 1
let OmniCpp_MayCompleteArrow = 1
let OmniCpp_MayCompleteScope = 1
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]

" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
set completeopt=menuone,menu,longest,preview
au BufNewFile,BufRead,BufEnter *.cpp,*.hpp set omnifunc=omni#cpp#complete#Main
set omnifunc=omni#cpp#complete#Main


" *******************************************************
" * Edit window management
" *******************************************************
set previewheight=20
set winfixheight

previewwindow

" *******************************************************
" * Edit window management
" *******************************************************

" Plugins which open window
let s:vimrc_pluginList = [
    \ "_NERD_tree_",
    \ "__Tag_List__",
    \ "Source_Explorer",
    \ "_MiniBufExplorer_",
    \ ".vimprojects",
\ ]

" Get the edit window number, avoiding plugins windows
function! s:Vimrc_GetEditWin()
  for winIdx in (range(1, winnr("$")))
    let l:found = winIdx
    for item in s:vimrc_pluginList
      "echo item "<==>" bufname(winbufnr(winIdx))
      if bufname(winbufnr(winIdx)) ==# item
        let l:found = 0
        break
      endif
    endfor
    if found > 0
      "echo "Selected window: " bufname(winbufnr(l:found))
      return l:found
    endif
  endfor
  return -1
endfunction

" Jump to the edit window, avoiding plugins windows
function! g:Vimrc_JumpEditWin()
  " We must get the edit window number
  let l:editwin = s:Vimrc_GetEditWin()
  " Not found
  if l:editwin < 0
    echohl ErrorMsg
      echo "Vimrc: can not find the edit window"
    echohl None
    return -1
  endif
  " Jump to that window
  silent! exe l:editwin . "wincmd w"
endfunction


" *******************************************************
" * Misc. settings
" *******************************************************




" *******************************************************
" * Trials
" *******************************************************

" Cycle through split windows
noremap  <Tab>   <C-W>w
noremap! <Tab>   <C-W>w
noremap  <S-Tab> <C-W>W
noremap! <S-Tab> <C-W>W

noremap  <C-Tab> <C-W>w
inoremap <C-Tab> <C-O><C-W>w
cnoremap <C-Tab> <C-C><C-W>w
onoremap <C-Tab> <C-C><C-W>w
noremap  <C-S-Tab> <C-W>W
inoremap <C-S-Tab> <C-O><C-W>W
cnoremap <C-S-Tab> <C-C><C-W>W
onoremap <C-S-Tab> <C-C><C-W>W

" Cycle through tabs
noremap  <C-Tab> <C-C>:tabn<CR>
noremap! <C-Tab> <C-C>:tabn<CR>
noremap  <S-C-Tab> <C-C>:tabp<CR>
noremap! <S-C-Tab> <C-C>:tabp<CR>

" New/Close tab
noremap <C-t> :tabnew<CR>
noremap <C-S-t> :close<CR>

" Ctrl-z/y to undo/redo
noremap <C-z> :u<CR>
noremap <C-y> <C-r><CR>

" Ctrl-S to save
noremap <C-s> :up<CR>

" Alt-left/right to navigate in history
noremap <A-left> :bp<CR>
noremap <A-right> :bn<CR>

" *******************************************************
" * Code align assignments
" *******************************************************
nmap <silent> <leader>= :call AlignAssignments()<CR>

function! AlignAssignments()
    "Patterns needed to locate assignment operators...
    let ASSIGN_OP   = '[-+*/%|&]\?=\@<!=[=~]\@!'
    let ASSIGN_LINE = '^\(.\{-}\)\s*\(' . ASSIGN_OP . '\)'

    "Locate block of code to be considered (same indentation, no blanks)
    let indent_pat = '^' . matchstr(getline('.'), '^\s*') . '\S'
    let firstline  = search('^\%('. indent_pat . '\)\@!','bnW') + 1
    let lastline   = search('^\%('. indent_pat . '\)\@!', 'nW') - 1
    if lastline < 0
        let lastline = line('$')
    endif

    "Find the column at which the operators should be aligned...
    let max_align_col = 0
    let max_op_width  = 0
    for linetext in getline(firstline, lastline)
        "Does this line have an assignment in it?
        let left_width = match(linetext, '\s*' . ASSIGN_OP)

        "If so, track the maximal assignment column and operator width...
        if left_width >= 0
            let max_align_col = max([max_align_col, left_width])

            let op_width      = strlen(matchstr(linetext, ASSIGN_OP))
            let max_op_width  = max([max_op_width, op_width+1])
         endif
    endfor

    "Code needed to reformat lines so as to align operators...
    let FORMATTER = '\=printf("%-*s%*s", max_align_col, submatch(1),
    \                                    max_op_width,  submatch(2))'

    " Reformat lines with operators aligned in the appropriate column...
    for linenum in range(firstline, lastline)
        let oldline = getline(linenum)
        let newline = substitute(oldline, ASSIGN_LINE, FORMATTER, "")
        call setline(linenum, newline)
    endfor
endfunction


" *******************************************************
" * Grep & open file
" *******************************************************
function! Find(name)
    let l:_name = substitute(a:name, "\\s", "*", "g" )
    let l:list  = system("find . -iname '*".l:_name."*' -type f -not -name \"*.swp\" | perl -ne 'print \"$.\\t$_\"'" )
    let l:num   = strlen(substitute(l:list, "[^\n]", "", "g" ))
    if l:num < 1
        echo "'".a:name."' not found"
        return
    endif

    if l:num != 1
        echo l:list
        let l:input = input("Which ? (<enter> = nothing)\n" )

        if strlen(l:input) == 0
            return
        endif

        if strlen(substitute(l:input, "[0-9]", "", "g" )) > 0
            echo "Not a number"
            return
        endif

        if l:input < 1 || l:input > l:num
            echo "Out of range"
            return
        endif

        let l:line = matchstr("\n".l:list, "\n".l:input."\t[^\n]*" )
    else
        let l:line = l:list
    endif

    let l:line = substitute(l:line, "^[^\t]*\t./", "", "" )
    execute ":bad ".l:line
    execute ":MiniBufExplorer"
    execute ":UMiniBufExplorer"
endfunction

command! -nargs=1 Find :call Find("<args>" )
map <leader>f :Fi-


" *******************************************************
" * Temporary code & maps
" *******************************************************

" Execute function when entering visual mode
"function! MyFunc()
"  :se nu!
"endfunction
"vnoremap <silent> <expr> <SID>MyFunc MyFunc()
"nnoremap <silent> <script> v v<SID>MyFunc<cr>

" *******************************************************
" * Trials
" *******************************************************

"augroup autotrinity
  "autocmd!
  "autocmd TabEnter * silent! sleep 200m | TrinityToggleAll
  "autocmd TabLeave * silent! sleep 200m | TrinityToggleAll
  "autocmd TabEnter *.c,*.cc silent! sleep 200m | TrinityToggleAll
  "autocmd TabLeave *.c,*.cc silent! sleep 200m | TrinityToggleAll
  "autocmd TabEnter * silent! sleep 200m | Trinity_InitSourceExplorer
  "autocmd TabLeave * silent! sleep 200m | SrcExplClose
"augroup END

"nmap <C-I> <C-W>j:call g:SrcExpl_Jump()<CR>
"nmap <C-O> :call g:SrcExpl_GoBack()<CR>

" *******************************************************
" * Trials
" *******************************************************

function! MyTags_GetInput(note)
  call inputsave()
  let l:input = input(a:note)
  call inputrestore()
  return l:input
endfunction

    " Ask user if or not create a tags file
    echohl Question
      \ | let l:tmp = MyTags_GetInput(
        "\nTags: "
        \ . "The 'tags' file was not found in your PATH.\n"
        \ . "Create one in the current directory now? (y)es/(n)o?")
      \ |
    echohl None



" Update tags file with the 'ctags' utility
function! MyTags_UpdateTags()

  " Go to the current work directory
  silent! exe "cd " . expand('%:p:h')

  " Get the amount of all files named 'tags'
  let l:tmp = len(tagfiles())

  " No tags file or not found one
  if l:tmp == 0

    " Ask user if or not create a tags file
    echohl Question
      call inputsave()
      let l:tmp = input(
        "\nTags: "
        \ . "The 'tags' file was not found in your PATH.\n"
        \ . "Create one in the current directory now? (y)es/(n)o?")
      call inputrestore()
    echohl None

    " Yes
    if l:tmp == "y" || l:tmp == "yes"

      " Tell user where we create a tags file
      echohl Question
        echo "Tags: Creating 'tags' file in (". expand('%:p:h') . ")"
      echohl None

      " Call the external 'ctags' utility program
      exe "!" . s:MyTags_updateTagsCmd

      " Rejudge the tags file if existed
      if !filereadable("tags")
        " Tell them what happened
        echohl ErrorMsg
          echo "Tags: Execute 'ctags' utility program failed"
        echohl None
        return -1
      endif

    " No
    else
      echo ""
      return -2
    endif

  " More than one tags file
  elseif l:tmp > 1
    echohl ErrorMsg
      echo "Tags: More than one tags file in your PATH"
    echohl None
    return -3

  " Found one successfully
  else

    " Is the tags file in the current directory ?
    if tagfiles()[0] ==# "tags"

        " Prompt the current work directory
        echohl Question
          echo "Tags: Updating 'tags' file in (". expand('%:p:h') . ")"
        echohl None

        " Call the external 'ctags' utility program
        exe "!" . s:MyTags_updateTagsCmd

    " Up to other directories
    else

        " Prompt the whole path of the tags file
        echohl Question
            echo "Tags: Updating 'tags' file in (". tagfiles()[0][:-6] . ")"
        echohl None

        " Store the current word directory at first
        let l:tmp = getcwd()

        " Go to the directory that contains the old tags file
        silent! exe "cd " . tagfiles()[0][:-5]

        " Call the external 'ctags' utility program
        exe "!" . s:MyTags_updateTagsCmd

       " Go back to the original work directory
       silent! exe "cd " . l:tmp
    endif
  endif

  return 0

endfunction


" *******************************************************
" * CCtree plugin
" *******************************************************
" Disable plugin
"let g:loaded_cctree = 1

" Configuration
let g:CCTreeCscopeDb = "cscope.out"
"let g:CCTreeDb = "cctree.out"
let g:CCTreeRecursiveDepth = 1
let g:CCTreeMinVisibleDepth = 1
"let g:CCTreeEnhancedSymbolProcessing = 0
let g:CCTreeKeyTraceForwardTree = '<C-A>>'
let g:CCTreeKeyTraceReverseTree = '<C-A><'
"let g:CCTreeKeyHilightTree = '<C-l>'  " Static highlighting
"let g:CCTreeKeySaveWindow = '<C-\>y'
"let g:CCTreeKeyToggleWindow = '<C-A>w'
"let g:CCTreeKeyCompressTree = 'zs'     " Compress call-tree
"let g:CCTreeKeyDepthPlus = '<C-\>='
"let g:CCTreeKeyDepthMinus = '<C-\>-'
let g:CCTreeOrientation = "belowright"
let g:CCTreeWindowVertical = 0
let g:CCTreeWindowWidth = -1
let g:CCTreeWindowMinWidth = 20
"let g:CCTreeWindowHeight = 8
"let g:CCTreeDisplayMode = 1
let g:CCTreeHilightCallTree = 0
"let g:CCTreeSplitProgCmd = 'PROG_SPLIT SPLIT_OPT SPLIT_SIZE IN_FILE OUT_FILE_PREFIX'
"let g:CCTreeSplitProg = 'split'
"let g:CCTreeSplitProgOption = '-C'
"let g:CCTreeDbFileSplitLines = -1
"let g:CCTreeSplitProgCmd = 'PROG_SPLIT SPLIT_OPT SPLIT_SIZE IN_FILE OUT_FILE_PREFIX'
"let g:CCTreeDbFileMaxSize = 40000000 "40 Mbytes
"let g:CCTreeJoinProgCmd = 'PROG_JOIN JOIN_OPT IN_FILES > OUT_FILE'
"let g:CCTreeJoinProg = 'cat'
"let g:CCTreeJoinProgOpts = ""
"let g:CCTreeUsePerl = 0
"let g:CCTreeUseUTF8Symbols = 0

let s:CCTreeRC = {
                    \ 'Error' : -1,
                    \ 'True' : 1,
                    \ 'False' : 0,
                    \ 'Success' : 2
                    \ }

function! CCTreeTraceSymbol(direction)
    if g:CCTreeGlobals.DbList.mIsEmpty() == s:CCTreeRC.True
        return
    endif
    let symbol = expand('<cword>')
    if symbol == ''
        return
    endif

    let symmatch = g:CCTreeGlobals.mGetSymNames(symbol)
    if len(symmatch) > 0 && index(symmatch, symbol) >= 0
        call g:CCTreeGlobals.mSetPreviewState(symbol,
                                            \ g:CCTreeRecursiveDepth,
                                            \ a:direction)
        call g:CCTreeGlobals.mUpdateForCurrentSymbol()
    endif
endfunction

"augroup CCTree_AutoCmd
"  autocmd!
"  au! WinEnter * nested CCTreeLoadDB
"  au! CursorHold * nested call CCTreeTraceSymbol('p')
"augroup end
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

<<<<<<< HEAD
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
=======
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
>>>>>>> 45cac51a08740a8dc3172f34b99c1567d1e0350b
endfunction

" Jump to the edit window, avoiding plugins windows
function! g:wndmgr_JumpEditWnd()
<<<<<<< HEAD
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
=======
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
>>>>>>> 45cac51a08740a8dc3172f34b99c1567d1e0350b
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
