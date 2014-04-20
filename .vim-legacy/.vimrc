" Notes {
" Based on Smylers's .vimrc
" 2000 Jun  1: for `Vim' 5.6
"
" Hints
" <C-C> goto normal mode
" <C-O> stay in insert mode to execute a single cmd
"
" Toggle key maps: <localleader>
" Action key maps: <leader>
"

" *******************************************************
" } Prepare environment {
" *******************************************************

" Version check
if v:version < 700
  echoe ".vimrc requires VIM 7.0 or above"
  finish
endif

" User commands check
if !has("user_commands") && !exists("g:reload_vimrc")
  " Reload .vimrc silently (removes autocommands errors)
  let g:reload_vimrc = 1
  silent! source $MYVIMRC
  finish
endif

" Use before config
if filereadable(expand("~/.vimrc.before"))
  source ~/.vimrc.before
endif


" *******************************************************
" } Select options {
" *******************************************************
if $VIM_USETABS != ""
  let g:vimrc_useTabs = 1
  " Disable MBE plugin
  let g:loaded_minibufexplorer = 1
endif

" Disable the following plugins
let g:loaded_project = 1
let g:loaded_taglist = 1
"let g:loaded_tagbar = 1
let g:loaded_srcexpl = 1
let g:loaded_nerd_tree = 1
let g:loaded_trinity = 1
let g:ccvext_version = 1
let g:loaded_yankring = 1
"let g:loaded_cctree = 1
let g:command_t_loaded = 1
"let g:loaded_minibufexplorer = 1
"let g:loaded_yaifa = 1
"let g:loaded_ctrlp = 1
let g:loaded_buftabs = 2 " 2 = skip loading
let g:loaded_easytags = 1
let g:loaded_bbye = 1


" *******************************************************
" } Global settings {
" *******************************************************
set path=.,,**              " Search path: recurse from current directory
let mapleader = ";"         " Leader key
let maplocalleader = ","    " Local leader key
set nobackup                " No backup
set noswapfile              " No swap
set noerrorbells            " No bells (!!)
set novisualbell            " No visual bells too
set updatetime=1000         " Swap file write / event CursorHold delay (in ms)
set shell=/bin/bash\ --rcfile\ ~/.bashrc\ -i    " Set shell, load user profile

" Force write with sudo after opening the file
cmap w!! w !sudo tee % >/dev/null


" *******************************************************
" } Key mapping functions {
" *******************************************************

" Map/noremap function keys (or Ctrl-X) in normal/visual & insert modes
function! FnMap(prefix, args)
  let args = matchlist(a:args,'\(<silent>\s\+\)\?\(.\{-}\)\s\+\(.*\)')
  execute a:prefix.'map'  args[1] args[2] '<c-c>'.args[3]
  execute 'i'.a:prefix.'map <expr>' args[1] args[2] (pumvisible()?'<ESC>':'<c-o>').args[3]
endfunction

" Make an alternate mapping based on another
function! DoAltNmap(new,old)
  if empty(maparg(a:new,'n')) && !empty(maparg(a:old,'n'))
    execute 'nmap' a:new a:old
  endif
endfunction

" Make alternate key mappings based on another one
function! AltNmap(new,old)
  call DoAltNmap('<'.a:new.'>', '<'.a:old.'>')
  call DoAltNmap('<S-'.a:new.'>', '<S-'.a:old.'>')
  call DoAltNmap('<C-'.a:new.'>', '<C-'.a:old.'>')
  call DoAltNmap('<A-'.a:new.'>', '<A-'.a:old.'>')
endfunction

" Conditionnal key remapping
function! s:CondRemap(mapfct, key, mode, condition, action)
  if mapcheck(a:key,a:mode)==''
    execute a:mapfct a:key a:action
  else
    execute a:mapfct a:key
           \ ":if" a:condition "<BAR>" a:action "<BAR> else <BAR>"
           \ substitute(mapcheck(a:key,a:mode),'<CR>\|:','','g') "<BAR> endif<CR>"
  endif
endfunction

" User commands
command! -nargs=1 FnMap      call FnMap('',<f-args>)
command! -nargs=1 FnNoremap  call FnMap('nore',<f-args>)
command! -nargs=+ AltNmap    call AltNmap(<f-args>)


" *******************************************************
" } Source vimrc {
" *******************************************************
" Resource vimrc
noremap  <leader>s      :source $MYVIMRC<CR>
cnoreabbrev reload source $MYVIMRC


" *******************************************************
" } Terminal Settings {
" *******************************************************
" `XTerm', `RXVT', `Gnome Terminal', and `Konsole' all claim to be "xterm";
" `KVT' claims to be "xterm-color":
if &term =~ 'xterm'

  " `Gnome Terminal' fortunately sets $COLORTERM; it needs <BkSpc> and <Del>
  " fixing, and it has a bug which causes spurious "c"s to appear, which can be
  " fixed by unsetting t_RV:
  if $COLORTERM == 'gnome-terminal'
    execute 'set t_kb=' . nr2char(8)
    " [Char 8 is <Ctrl>+H.]
    fixdel
    set t_RV=

  " `XTerm', `Konsole', and `KVT' all also need <BkSpc> and <Del> fixing;
  " there's no easy way of distinguishing these terminals from other things
  " that claim to be "xterm", but `RXVT' sets $COLORTERM to "rxvt" and these
  " don't:
  elseif $COLORTERM == ''
    execute 'set t_kb=' . nr2char(8)
    fixdel

  " The above won't work if an `XTerm' or `KVT' is started from within a `Gnome
  " Terminal' or an `RXVT': the $COLORTERM setting will propagate; it's always
  " OK with `Konsole' which explicitly sets $COLORTERM to "".
  endif
endif


" *******************************************************
" } User Interface {
" *******************************************************

" Theme & color scheme
if has('syntax') && (has("gui_running") || (&t_Co > 2))
  colorscheme torte   " Theme
  syntax on           " Syntax highlight
endif

set hlsearch          " Highlight searches
set history=50        " History length
set wildmode=list:longest,full    " Command line completion with Tabs & cycling
set shortmess+=r      " Use "[RO]" instead of "[readonly]"
set shortmess+=a      " Use short messages
set showmode          " Display current mode in the status line
set showcmd           " Display partially-typed commands
set mouse=a           " Enable mouse all the time
set nomodeline        " Do not override this .vimrc
if !exists('g:loaded_vimrc')
  set nu              " Show line numbers
endif
set hidden            " Show hidden buffers & allow switching to modified buffer
set switchbuf=useopen " Buffer switch use open windows instead of splitting/openning new window
set noea              " No equalize windows
set splitbelow        " Window split location. Also applied to :vsp & :sp
set splitright        " Window split location. Also applied to :vsp & :sp
set nofoldenable      " Disable folding

" Save/restore part of edit session
"  /10  :  search items
"  '10  :  marks in 10 previously edited files
"  r/mnt/zip,r/mnt/floppy : excluded locations
"  "100 :  100 lines for each register
"  :20  :  20 lines of command-line history
"  %    :  buffer list
"  n... :  viminfo file location
set viminfo='10,\"100,:20,n~/.viminfo

" When using list, keep tabs at their full width and display `arrows':
" (Character 187 is a right double-chevron, and 183 a mid-dot.)
execute 'set listchars+=tab:' . nr2char(187) . nr2char(183)

" Gui options
set guioptions-=T       " Remove toolbar

" Jump to the last cursor position
augroup vimrc_cursor_lastpos
  autocmd! BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
augroup END

" Key maps
map <localleader>n  :set nu!<CR>


" *******************************************************
" } Text Formatting {
" *******************************************************
set guioptions+=rb    " Right/bottom scroll bars enabled
set formatoptions-=t  " Do not format text as it is typed

set tabstop=4         " Indents of 4
set shiftwidth=4      " Indents of 4
set shiftround        " Indents are copied down lines
set autoindent        " Auto-indent
if !exists('g:loaded_vimrc')
  set expandtab       " Expand tabs to spaces
endif

set comments-=s1:/*,mb:*,ex:*/    " Get rid of the default style of C comments
set comments+=s:/*,mb:**,ex:*/    " Define new comment style starting with '**'
set comments+=fb:*                " Prevent single '*' lists to be intepreted as comments

" treat lines starting with a quote mark as comments (for `Vim' files, such as
" this very one!), and colons as well so that reformatting usenet messages from
" `Tin' users works OK:
set comments+=b:\"    " Define comment starting with '"'
set comments+=n::     " Define comment starting with ':'

" File type detection
filetype on           " enable filetype detection:

" C-like: automatic indentation
"autocmd! FileType c,cc,cpp,slang set cindent tabstop=4 expandtab
autocmd! FileType c,cc,cpp,slang set cindent

" C: allow comments starting in the middle of a line
autocmd! FileType c set formatoptions+=ro

" Python: no tab to space, enable auto indentation
"autocmd! FileType python set noexpandtab tabstop=4 smartindent
autocmd! FileType python set noexpandtab smartindent

" Makefile: no tab to space, tab width 4 chars
"autocmd! FileType make set noexpandtab shiftwidth=4
autocmd! FileType make set noexpandtab

" Word/line wrap options
set nowrap              " No wrap by default
nnoremap <localleader>w  :set invwrap<CR>
"nnoremap <localleader>w  :exec &wrap?'set nowrap':'set wrap linebreak nolist'<CR>

" Show all characters
set nolist              " Do not show all characters by default
nnoremap <localleader>c  :set invlist<CR>
"nnoremap <localleader>c  :exec &list?'set nolist':'set list'<CR>


" *******************************************************
" } Directory management {
" *******************************************************

" Look for the best root directory
function! s:FindRootDir()
  " Ctags/cscope files
  for file in [g:tags_db, g:cscope_db]
    let file = findfile(file, ".;")
    if (filereadable(file))
      return fnamemodify(file, ':p:h')
    endif
  endfor
  " SVN/GIT directory
  for dir in ['.svn', '.git']
    let _dir = finddir(dir, ".;", -1)
    if (!empty(_dir))
      return _dir[-1] . '/..'
    endif
  endfor
  " No match
  return ''
endfunction

" Directory autochange
if 1
  " Look for the best directory
  autocmd! BufEnter * execute "lcd" s:FindRootDir()
elseif exists('+autochdir')
  " Automated directory change
  set autochdir
else
  " Autocommand directory change
  augroup vimrc_autochdir
    autocmd! BufEnter * silent! lcd %:p:h:gs/ /\\ /
  augroup END
endif

" Change global directory to the current directory of the current buffer
nnoremap <leader>c :cd %:p:h<CR>


" *******************************************************
" } Load plugins {
" *******************************************************
" Start plugin pathogen
filetype off                " force reloading *after* pathogen loaded
runtime bundle/pathogen/autoload/pathogen.vim
execute pathogen#infect()
filetype plugin indent on   " enable detection, plugins and indenting in one step


" *******************************************************
" } Mswin plugin - its settings may be overriden afterwards {
" *******************************************************

" Additional key mapping
vmap <C-z>  <C-c><C-z>
vmap <C-y>  <C-c><C-y>


" *******************************************************
" } Diff {
" *******************************************************
" Options
set diffopt=vertical,filler,context:4

" Color scheme
highlight DiffAdd cterm=none ctermfg=bg ctermbg=Green gui=none guifg=bg guibg=Green
highlight DiffDelete cterm=none ctermfg=bg ctermbg=Red gui=none guifg=bg guibg=Red
highlight DiffChange cterm=none ctermfg=bg ctermbg=Yellow gui=none guifg=bg guibg=Yellow
highlight DiffText cterm=none ctermfg=bg ctermbg=Magenta gui=none guifg=bg guibg=Magenta

" Key mapping
noremap <localleader>d      :diffthis<CR>
noremap <localleader>dd     :diffthis<BAR>vsp<CR>
noremap <localleader>ds     :diffsplit<SPACE>
noremap <localleader>dc     :diffoff!<CR>
noremap <localleader>du     :diffupdate<CR>
FnNoremap <silent><F8>      [c
FnNoremap <silent><S-F8>    ]c
nnoremap <silent>h          [c<CR>
nnoremap <silent>H          ]c<CR>


" *******************************************************
" } Formatting {
" *******************************************************
" Indentation normal & visual modes
nnoremap <Tab>   >>
vnoremap <Tab>   >
nnoremap <S-Tab> <LT><LT>
vnoremap <S-Tab> <LT>

" Identation insert mode
"inoremap <Tab>   <C-T>
"inoremap <S-Tab> <C-D>

" Y behave like C and D (not like cc, dd, yy)
noremap Y y$

" Word quote
nnoremap <silent> <leader>" viw<esc>a"<esc>hbi"<esc>lel

" Upper/lower case
vnoremap <silent> <C-u>     U
vnoremap <silent> <C-l>     L


" *******************************************************
" } Space to tabs / tab to spaces {
" *******************************************************

" Tab to space
function! s:Tab2Space() range
  let firstline = a:firstline == a:lastline ? 0 : a:firstline
  let lastline = a:firstline == a:lastline ? line('$') : a:lastline
  execute ':'.firstline.','.lastline.'s#^\t\+#\=repeat(" ", len(submatch(0))*' . &ts . ')'
endfunction

" Space to tab
function! s:Space2Tab() range
  let firstline = a:firstline == a:lastline ? 0 : a:firstline
  let lastline = a:firstline == a:lastline ? line('$') : a:lastline
  execute ':'.firstline.','.lastline.'s#^\( \{'.&ts.'\}\)\+#\=repeat("\t", len(submatch(0))/' . &ts . ')'
endfunction

" Intelligent tab to spaces
function! s:Tabfix() abort
  if &expandtab==0
    call s:Tab2Space()
  else
    call s:Space2Tab()
  endif
  update
  YAIFAMagic
endfunction

" User commands
command! -range=% -nargs=0 Tab2Space call <SID>Tab2Space()
command! -range=% -nargs=0 Space2Tab call <SID>Space2Tab()
command! -range=% -nargs=0 Tabfix    call <SID>Tabfix()

" Key mapping
noremap <leader><Tab> :call <SID>Tabfix()<CR>


" *******************************************************
" } Space & tabs highlight {
" *******************************************************

" Show unwanted extra white space and tab characters
if !exists('s:spaceTabHighlight')
  let s:spaceTabHighlight = 0
endif

" Highlight unwanted space and tabs
function! s:SpaceTabHighlight(switchOn)
  if a:switchOn == 1
    " Set color
    hi ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
    hi ExtraTabs ctermbg=darkgreen guibg=darkgreen
    " Show trailing spaces and spaces before a tab
    syn match ExtraWhitespace /\s\+$\| \+\ze\t/
    if &expandtab==0
      " Show spaces wrongly used for indenting
      " Show tabs that are not at the start of a line
      syn match ExtraTabs /^\t*\zs \+\|[^\t]\zs\t\+/
    else
      " Show tabs that are not at the start of a line
      syn match ExtraTabs /[^\t]\zs\t\+/
    endif
  else
    " Enable syntax back
    syn on
  endif
endfunction

" Highlight unwanted space and tabs
function! s:SpaceTabToggle()
  let s:spaceTabHighlight = !s:spaceTabHighlight
  call <SID>SpaceTabHighlight(s:spaceTabHighlight)
endfunction

" Key mapping
map <silent><localleader>v  :call <SID>SpaceTabToggle()<CR>


" *******************************************************
" } Search {
" *******************************************************
set ignorecase      " Case-insensitive search
set smartcase       " Unless search contain upper-case letters
set incsearch       " Show the `best match so far' when search is typed
set nogdefault      " Assume /g flag (replace all) is NOT set

" Highlight current selection
function! s:SearchHighlight()
  let old_reg=getreg('"')
  let old_regtype=getregtype('"')
  execute "normal! gvy"
  let @/=substitute(escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')
  execute "normal! gV"
  call setreg('"', old_reg, old_regtype)
  set hls
endfunction

" Toggle search highlighting
nnoremap <localleader><F3>  :set invhls hls?<CR>
nnoremap <localleader>f     :set invhls hls?<CR>

" Search & replace
FnNoremap <C-F>     /
FnNoremap <C-A-F>   yiw:/<C-R>"
vnoremap <C-F>      "+y:/<C-R>"
cnoremap <C-F>      <NOP> |" Disable command line window (use q: q/ q? instead)

" F3 for search (n and N)
FnMap  <F3>         n
FnMap  <S-F3>       N
FnMap  <C-F3>       :nohl<CR>
vmap <S-F3>         <F3>N
vnoremap <silent>   <F3> :<C-u>call <SID>SearchHighlight()<CR>
vnoremap <C-F3>     :nohl<CR>

" Alternative search
nmap <silent>f      n
nmap <silent>F      N

" F4 for select & search (* and #)
FnMap <F4>          *
FnMap <S-F4>        #
nmap µ              #


" *******************************************************
" } Find search {
" *******************************************************
" Find files
function! s:Find(files, ...)
  let path  = escape(s:FindRootDir().'/'.a:files, '" *')
  execute 'Wsys' '_find' path join(a:000)
endfunction

" Abbreviations
cnoreabbrev ff Find

" User commands
command! -nargs=+ -bar Find call <SID>Find(<f-args>)

" Keymapping
FnNoremap <C-A-H>   :Find<SPACE>
vnoremap  <C-A-H>   "+y:Find <C-R>"


" *******************************************************
" } Sed & replace {
" *******************************************************
" Sed (replace in files)
function! s:Sed(pattern, replace, files, ...)
  let path  = '"'.escape(s:FindRootDir().'/'.a:files, ' ').'"'
  let expr1 = '"'.escape(a:pattern, '" *').'"'
  let expr2 = '"'.escape(a:replace, '" *').'"'
  execute '!_fsed' join(a:000) expr1 expr2 path
endfunction

" User commands
command! -nargs=+ -bar Sed  call <SID>Sed(<f-args>)

" Sed keymapping
FnNoremap <C-A-H>   :Sed<SPACE>
vnoremap  <C-A-H>   "+y:Sed <C-R>"

" Replace keymapping
FnNoremap <C-H>     :%s///cg<left><left><left><left>
"FnNoremap <C-A-H>   yiw:%s/<C-R>"/<C-R>"/cg<left><left><left>
vnoremap  <C-H>     "+y:%s/<C-R>"/<C-R>"/cg<left><left><left>
"vnoremap  <C-A-H>   "+y:%s/<C-R>"//cg<left><left>


" *******************************************************
" } Grep {
" *******************************************************
" Grep program
set grepprg=ref\ $*
"set grepprg=lid\ -Rgrep\ -s
"set grepformat=%f:%l:%m

" Abbreviations
cnoreabbrev gg Grep

" Grep
function! s:Grep(expr)
  let path = escape(s:FindRootDir(), '" *')
  let expr = escape('"'.a:expr.'"','" *')
  execute 'Wcmd' 'grep!' expr path
endfunction

" Count expression
function! s:GrepCount(expr)
  let path = escape(s:FindRootDir(), '" *')
  let expr = escape('"'.a:expr.'"','" *')
  execute '!ref' expr path '| wc -l'
endfunction

" User commands
command! -nargs=1 -bar Grep      call <SID>Grep(<q-args>)
command! -nargs=1 -bar GrepCount call <SID>GrepCount(<q-args>)

" Key mappings
silent! unmap gx
nnoremap <silent>g          :Wnext<CR>
nnoremap <silent>G          :Wprev<CR>
nnoremap <C-g>              :Grep<SPACE>
"nnoremap <C-g><C-g>         :Grep<SPACE><C-r><C-w>
vnoremap <C-g>              "+y:Grep<SPACE><C-r>"
nnoremap <A-g>              :GrepCount<SPACE><C-r><C-w>


" *******************************************************
" } Make {
" *******************************************************
" Make program
"set makeprg=make\ $*
"set makeformat=%f:%l:%m

" Abbrevations
"cnoreabbrev make lmake

" Fix make errors encoding
function! QfRemoveAnsiColor()
  let qflist = getqflist()
  for i in qflist
    "let i.text = iconv(i.text, "cp936", "utf-8")
    let i.text = substitute(i.text, "\e[\d+;\d+m", "", "g")
   endfor
   call setqflist(qflist)
endfunction

" Autocommands
if has('quickfix')
  autocmd! QuickfixCmdPost make call QfRemoveAnsiColor()
endif


" *******************************************************
" } Cursor management {
" *******************************************************
set whichwrap=h,l,~,[,]   " Wrap between lines for h, l, ~, cursor keys [ and ]
set matchpairs+=<:>       " '%' bounce between brackets

" Backspace delete line breaks, over the start of the
" current insertion, and over indentations
set backspace=indent,eol,start

" Jump to line
FnNoremap  <C-j> :
vnoremap <C-j>  <C-c>:

" Prev/next cursor location
" Note: <C-[> is Esc, <C-c> exits visual mode
FnNoremap <A-Left>  <C-O>
FnNoremap <A-Right> <C-I>
vnoremap <A-Left>  <C-c><C-O>
vnoremap <A-Right> <C-c><C-I>


" *******************************************************
" } Tab management {
" *******************************************************
" Options
if exists('g:vimrc_useTabs')
  silent! set switchbuf=usetab,newtab  " Buffer switch
endif
if exists('+gtl') " Tab name is the filename only
  set gtl=%t
endif

" Open/close tab
FnMap  <C-t>            :tabnew<CR>
FnMap  <C-t><C-t>       :tabe<SPACE>
FnMap  <C-t><C-c>       :tabclose<CR>
if exists('g:vimrc_useTabs')
  FnNoremap  <C-F4>     :tabclose<CR>
  FnNoremap  <C-S-F4>   :tabdo tabclose<CR>
endif

" Prev/next tab
if exists('g:vimrc_useTabs')
  FnNoremap  <C-Tab>    :tabn<CR>
  FnNoremap  <C-S-Tab>  :tabp<CR>
else
  FnNoremap  <C-PgUp>   :tabn<CR>
  FnNoremap  <C-PgDown> :tabp<CR>
endif

" Autocommands
if exists('g:vimrc_useTabs')
  if (&diff==0) " no in diff mode
    " Open in tab allways
    augroup vimrc_tab
      autocmd! BufReadPost * tab ball
    augroup END
  endif
endif


" *******************************************************
" } Window management {
" *******************************************************
" Open/close window : standard mappings <C-w>...
" Prev/next window (Ctrl-w/W)

" Go up/down/left/right window
FnNoremap <C-Up>      :wincmd k<CR>
FnNoremap <C-Down>    :wincmd j<CR>
FnNoremap <C-Left>    :wincmd h<CR>
FnNoremap <C-Right>   :wincmd l<CR>

" Resize current window by +/- 5
" Same as 5<C-w>+  5<C-w>-  5<C-w>>  5<C-w><
"nnoremap <C-w><left>   :vertical resize -5<cr>
"nnoremap <C-w><right>  :vertical resize +5<cr>
"nnoremap <C-w><up>     :resize -5<cr>
"nnoremap <C-w><down>   :resize +5<cr>

" Extend window through the splits...
" Same as <C-w>_  <C-w>|
"noremap <C-J>  <C-w>j<C-w>_
"noremap <C-K>  <C-w>k<C-w>_
"noremap <C-H>  <C-w>h<C-w>\|
"noremap <C-L>  <C-w>l<C-w>\|

" Exit to normal when changing windows
augroup exit_to_normal
  autocmd! WinEnter * stopinsert
augroup END

" Zoom In/out window
function! s:ZoomWindow() abort
  if exists('s:zw_restore')
    execute s:zw_restore
    unlet s:zw_restore
    au! ZoomWindow
  else
    let s:zw_restore = winrestcmd()
    "vert resize
    wincmd _
    wincmd |
    augroup ZoomWindow
      au! WinLeave * call s:ZoomWindow()
    augroup END
  endif
endfunction

" Toggles window max/equal
function! s:WndToggleMax()
  if exists('s:wndMaxFlag')
    au! maxCurrWin
    wincmd =
    unlet s:wndMaxFlag
  else
    augroup maxCurrWin
      au! WinEnter * wincmd _ | wincmd |
    augroup END
    do maxCurrWin WinEnter
    let s:wndMaxFlag=1
  endif
endfunction

" Key maps
nnoremap <localleader>w     :call <SID>WndToggleMax()<CR>
nnoremap <localleader>x     :call <SID>ZoomWindow()<CR>
nnoremap x                  :call <SID>ZoomWindow()<CR>


" *******************************************************
" } Buffer management {
" *******************************************************
" Close buffer
function! s:BufClose(...)
  let idx=''
  if a:0
    let idx=a:1
  endif
  if exists(':Bdelete')
    execute 'silent! Bdelete' idx
  elseif exists(':MBEbd')
    execute 'MBEbd' idx
  else
    bdelete idx
  endif
endfunction

" Close buffers with given extension
function! s:BufCloseByExt(ext)
  let last = bufnr('$')
  let idx = 1
  while idx <= last
    if bufexists(idx) && bufname(idx) =~ a:ext.'$'
      execute 'BufClose' idx
    endif
    let idx = idx + 1
  endwhile
endfunction

" Cycle through each buffer, ask to close
function! s:BufCloseAll(...)
  let last = bufnr('$')
  let idx = 1
  while idx <= last
    if bufexists(idx) && getbufvar(idx, '&modifiable')
      if (a:0 && !a:1) || confirm("Close buffer '".bufname(idx)."'?", "&yes\n&no", 1)==1
        execute 'BufClose' idx
      endif
    endif
    let idx = idx + 1
  endwhile
endfunction

" Intelligent open related buffer
let s:vimrc_bufopenext = ['h','cc','c']
function! s:BufSmartOpen()
  for file in ['<cfile>', '%']
    " Skip non-existent files
    if !filereadable(expand(file))
      continue
    endif
    " Try few extensions
    for ext in s:vimrc_bufopenext
      " Search in the same directory
      let open_file = expand(file.":r") . '.' . ext
      if open_file!=?expand("%") && filereadable(open_file)
        silent! execute ':e' fnameescape(open_file)
        return
      endif
      " Search with tags and cscope
      let open_file = expand(file.":t:r") . '.' . ext
      if open_file!=?expand("%:t")
        silent! execute "tag" open_file | return
        if has('cscope')
          set nocscopeverbose
          execute "cs f f" open_file | return
          set cscopeverbose
        endif
      endif
    endfor
  endfor
endfunction

" User commands
command! -nargs=? BufClose call s:BufClose(<f-args>)
command! -nargs=1 BufCloseByExt call s:BufCloseByExt(<f-args>)
command! -nargs=? BufCloseAll   call s:BufCloseAll(<f-args>)
command! -nargs=0 BufSmartOpen  call s:BufSmartOpen()

" Open/close buffer (close=:bd or :bw)
map <C-b>           :e<SPACE><C-R>=expand("%:p:h") . "/" <CR>
map <C-b><C-b>      :BufSmartOpen<CR>
map <C-b><C-c>      :BufClose<CR>
map <C-q>           :BufClose<CR>
if !exists("g:vimrc_useTabs")
  FnMap <C-F4>      :BufClose<CR>
  FnMap <C-S-F4>    :BufCloseAll 1<CR>
endif

" Prev/next buffer
map  <C-b><C-n>       :bn<CR>
map  <C-b><C-p>       :bp<CR>
FnNoremap <A-Down>    :bp<CR>
FnNoremap <A-Up>      :bn<CR>
if !exists("g:vimrc_useTabs")
  FnNoremap <C-Tab>   :bn<CR>
  FnNoremap <C-S-Tab> :bp<CR>
endif

" Wide empty buffer at startup
if bufname('%') == ''
  set bufhidden=wipe
endif


" *******************************************************
" } Function keys {
" *******************************************************
" Fx keys in insert mode = normal mode
for idx in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  execute "imap <F" . idx . "> <C-O><F" . idx . ">"
endfor

" Map F1 to the help
FnMap <F1>    :vert help<SPACE>


" *******************************************************
" } Statusline {
" *******************************************************

" Returns "mixed" when indentation is mixed
function! b:StatuslineWarning()
  if !exists("b:statusline_tab_warning")
    let tabs = search('^\t', 'nw')
    let spaces = search('^ \+[^\*]', 'nw')
    if tabs && spaces
      let b:statusline_tab_warning =  '-mixed '.(&et ? tabs : spaces)
    elseif (spaces && !&et) || (tabs && &et)
      let b:statusline_tab_warning = '-error'
    else
      let b:statusline_tab_warning = ''
    endif
  endif
  return b:statusline_tab_warning
endfunction

" Set global status line content
function! s:StatuslineGlobal()
  if has("statusline") && &modifiable
    if exists('g:loaded_buftabs') && g:loaded_buftabs==1
      set statusline=\ %{buftabs#statusline(-45)}
    else
      set statusline=\ %<%F
    endif
    set statusline+=\ %=
    set statusline+=\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%m%r
    set statusline+=\ [%{&expandtab==0?'tabs':'space'}%{b:StatuslineWarning()}]
    set statusline+=\ %y\ %c,%l/%L\ %P
  endif
endfunction

" Hide status line
function! s:StatusLineHide()
    hi StatusLine ctermbg=NONE ctermfg=white
    hi clear StatusLine
    set laststatus=0
endfunction

" Line options
set laststatus=2                " Always show status line

" User command
command! -range=% -nargs=0 StatuslineGlobal call <SID>StatuslineGlobal(<f-args>)

" Update the warning flag
autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning

" Key mapping
noremap <silent><localleader>s  :call <SID>StatuslineGlobal()<CR>

" Set the status line once
if !exists("g:loaded_vimrc")
  call s:StatuslineGlobal()
endif


" *******************************************************
" } Marks {
" *******************************************************

" Marks variables
if !exists("s:mark_next")
  let s:mark_cur=0
  let s:mark_next=0
  let s:mark_max=1
endif

" Set a mark
function! s:MarkSet()
  if &buftype!=#'quickfix' && !&pvw
    exec printf("ma %c", 65 + s:mark_next)
    let s:mark_cur=s:mark_next
    let s:mark_next=(s:mark_next + 1) % 26
    let s:mark_max=max([s:mark_next,s:mark_max])
  else
    execute "normal! \<ENTER>"
  endif
endfunction

" Goto next mark
function! s:MarkNext()
  let s:mark_cur=(s:mark_cur + 1) % s:mark_max
  silent! exec printf("normal '%c", 65 + s:mark_cur)
endfunction

" Goto prev mark
function! s:MarkPrev()
  let s:mark_cur=(s:mark_cur + s:mark_max - 1) % s:mark_max
  silent! exec printf("normal '%c", 65 + s:mark_cur)
endfunction

" Reset all user marks
function! s:MarkReset()
  delmarks A-Z0-9
endfunction

" User commands
command! -nargs=0 -bar Mset   call <SID>MarkSet()
command! -nargs=0 -bar Mnext  call <SID>MarkNext()
command! -nargs=0 -bar Mprev  call <SID>MarkPrev()
command! -nargs=0 -bar Mreset call <SID>MarkReset()

" Mark key maps
FnMap <silent><F2>      :Mnext<CR>
FnMap <silent><S-F2>    :Mprev<CR>
FnMap <silent><C-F2>    :Mset<CR>
FnMap <silent><A-F2>    :Mreset<CR>
nmap <silent>m          :Mnext<CR>
nmap <silent>M          :Mprev<CR>
nmap <silent><C-m>      :Mset<CR>
nmap <silent><A-m>      :Mreset<CR>


" *******************************************************
" } Generic tag window management {
" *******************************************************
" Default windows
let g:wdefault = 'c'

" Select the right action list based on the current context
function! s:Wprefix()
  return (&previewwindow ? 'p' : (&buftype==?"quickfix" ? s:Qtype() : g:wdefault))
endfunction

" Search next
function! s:Wnext(prefix)
  try | silent execute a:prefix . "next" | catch | silent! execute a:prefix . "first" | endtry
endfunction

" Search prev
function! s:Wprev(prefix)
  try | silent execute a:prefix . "prev" | catch | silent! execute a:prefix . "last" | endtry
endfunction

" Execute system commands in quickfix or location window
function! s:Wsys(prefix, ...)
  execute a:prefix . "getexpr system('" . escape(join(a:000),"\"") . "')"
endfunction

" Execute vim commands in quickfix or location window
function! s:Wcmd(prefix, ...)
  execute (a:prefix==?'c' ? "" : a:prefix) . join(a:000)
endfunction

" User commands
command! -nargs=0 -bar Wopen    execute toupper(s:Wprefix()).'open'
command! -nargs=0 -bar Wclose   execute toupper(s:Wprefix()).'close'
command! -nargs=0 -bar Wtoggle  execute toupper(s:Wprefix()).'toggle'
command! -nargs=0 -bar Wnext    execute toupper(s:Wprefix()).'next'
command! -nargs=0 -bar Wprev    execute toupper(s:Wprefix()).'prev'
command! -nargs=+ -bar Wsys     call s:Wsys(g:wdefault,<f-args>)
command! -nargs=+ -bar Wcmd     call s:Wcmd(g:wdefault,<f-args>)

" Generic keymapping
FnNoremap <silent><C-SPACE>     :Wtoggle<CR>
nnoremap <silent><SPACE>        :Wnext<CR>
nnoremap <silent><S-SPACE>      :Wprev<CR>


" *******************************************************
" } Quickfix window management {
" *******************************************************
" Find if the given buffer is quickfix or location
function! s:Qtype(...)
  return (&buftype==?"quickfix" ? (exists("w:quickfix_title") && w:quickfix_title[1]==?"l" ? "l" : "c") : "")
"  let bufselect = (a:0 ? a:1 : '%')
"  if (!empty(bufselect) && getbufvar(bufselect,'&buftype')!=?"quickfix")
"    return ''
"  endif
"  " Get 'ls' output as a string
"  let ls_output = '' | redir =>> ls_output | silent! ls | redir END
"  " Match with quicklist string identifier
"  let matches = matchlist(ls_output, '\n\s*\(\d\+\).\{-,10}\[.\{-,10}Quickfix')
"  return (!empty(matches) && (empty(bufselect) || bufnr(bufselect)==matches[1]) ? 'c' : 'l')
endfunction

" User commands
command! -nargs=0 -bar Copen    bot copen
command! -nargs=0 -bar Cclose   cclose
command! -nargs=0 -bar Ctoggle  if s:Qtype('')==?'c' | Cclose | else | Copen | endif
command! -nargs=0 -bar Cnext    call s:Wnext('c')
command! -nargs=0 -bar Cprev    call s:Wprev('c')
command! -nargs=+ -bar Csys     call s:Wsys('c',<f-args>)
command! -nargs=+ -bar Ccmd     call s:Wcmd('c',<f-args>)

" Keymapping
nnoremap <localleader>c   :Ctoggle<CR>
nnoremap <silent>c        :Cnext<CR>
nnoremap <silent>C        :Cprev<CR>

" Autocommands
"if has('quickfix')
"  autocmd! QuickFixCmdPost [^l]* nested Copen
"endif


" *******************************************************
" } Location window management {
" *******************************************************

" User commands
command! -nargs=0 -bar Lopen    bot lopen
command! -nargs=0 -bar Lclose   lclose
command! -nargs=0 -bar Ltoggle  if s:Qtype('')==?'l' | Lclose | else | Lopen | endif
command! -nargs=0 -bar Lnext    call s:Wnext('l')
command! -nargs=0 -bar Lprev    call s:Wprev('l')
command! -nargs=+ -bar Lsys     call s:Wsys('l',<f-args>)
command! -nargs=+ -bar Lcmd     call s:Wcmd('l',<f-args>)

" Keymapping
nnoremap <localleader>l   :Ltoggle<CR>
nnoremap <silent>l        :Lnext<CR>
nnoremap <silent>L        :Lprev<CR>

" Autocommands (note: ltag is not concerned...)
"if has('quickfix')
"  autocmd! QuickFixCmdPost l* nested Lopen
"  autocmd! QuickFixCmdPost l* nested call setqflist(getloclist(0))
"endif


" *******************************************************
" } Tags {
" *******************************************************
" Set tags root
let g:tags_db='tags'
"set tags=./tags,tags;$HOME
set tags=./tags;$HOME

" User commands
command! -nargs=0 -bar Tnext    call s:Wnext('t')
command! -nargs=0 -bar Tprev    call s:Wprev('t')
command! -nargs=0 -bar Ttag     execute 'ltag' expand('<cword>') | call setqflist(getloclist(0))

" Key mapping
noremap <C-ENTER>           :Ttag<CR>
noremap <C-BACKSPACE>       <C-t>
nnoremap <silent>t          :execute (&previewwindow ? 'P' : 'T').'next'<CR>
nnoremap <silent>T          :execute (&previewwindow ? 'P' : 'T').'prev'<CR>


" *******************************************************
" } Preview window {
" *******************************************************
" Options
set previewheight=12          " Preview window height

" Variables
if !exists('s:p_lastw')
  let s:p_lastw = ""
  let s:p_highlight = 0
  let s:p_center = 0
endif

" Open preview window
function! s:PreviewOpenWnd()
  silent! execute "bot pedit!"
  wincmd P
  if &previewwindow
    set nu
    "wincmd J
    wincmd p
  endif
  let s:p_lastw = ""
  augroup PreviewWnd
    au! CursorHold * nested call s:PreviewShowTag()
  augroup END
endfunction

" Close preview window
function! s:PreviewCloseWnd()
  augroup PreviewWnd
    au!
  augroup END
  pclose
  unlet s:p_lastw
endfunction

" Toggle preview window
function! s:PreviewToggleWnd()
  silent! wincmd P
  if &previewwindow
    wincmd p
    call s:PreviewCloseWnd()
  else
    call s:PreviewOpenWnd()
  endif
endfunction

function! s:PreviewShowTag()
  if &previewwindow             " don't do this in the preview window
    return
  endif
  let w = expand("<cword>")     " get the word under cursor
  if w == s:p_lastw             " Same word, skip all this
    return
  endif
  let s:p_lastw = w
  if w =~ '\a'                  " if the word contains a letter
    " Try displaying a matching tag for the word under the cursor
    try
      exec "silent! ptag " . w
      if s:p_highlight
        call s:PreviewHighlightTag(w)
      endif
      if s:p_center
        call s:PreviewCenterTag()
      endif
    endtry
  endif
endfunction

function! s:PreviewCenterTag()
  silent! wincmd P            " jump to preview window
  if &previewwindow           " if we really get there...
    normal! zz                " Center
    wincmd p                  " back to old window
  endif
endfunction

function! s:PreviewHighlightTag(pattern)
  silent! wincmd P            " jump to preview window
  if &previewwindow           " if we really get there...
    match none                " delete existing highlight
    if has("folding")
      silent! .foldopen        " don't want a closed fold
    endif
    call search("$", "b")      " to end of previous line
    let w = substitute(a:pattern, '\\', '\\\\', "")
    call search('\<\V' . w . '\>') " position cursor on match
    " Add a match highlight to the word at this position
    hi previewWord term=bold ctermbg=blue guibg=blue
    exe 'match previewWord "\%' . line(".") . 'l\%' . col(".") . 'c\k*"'
    wincmd p                  " back to old window
  endif
endfunction

" User commands
command! -nargs=0 -bar Popen    call s:PreviewOpenWnd()
command! -nargs=0 -bar Pclose   call s:PreviewCloseWnd()
command! -nargs=0 -bar Ptoggle  call s:PreviewToggleWnd()
command! -nargs=0 -bar Pnext    call s:Wnext('pt')
command! -nargs=0 -bar Pprev    call s:Wprev('pt')
command! -nargs=0 -bar Ptag     call s:PreviewShowTag()

" Key mapping
nmap <localleader>p             :Ptoggle<CR>


" *******************************************************
" } File browser netrw {
" *******************************************************
" Options
let g:netrw_browse_split = 0  " Use same(0)/prev(4) window
let g:netrw_altv = 1          " Vertical split right
let g:netrw_liststyle=3       " Tree mode
let g:netrw_special_syntax= 1 " Show special files
let g:netrw_sort_sequence   = "[\/]$,*,\.o$,\.obj$,\.info$,\.swp$,\.bak$,\~$"
let g:netrw_winsize = 20      " Window size

" Workaround
set winfixwidth
set winfixheight

" Keymapping
FnNoremap <silent> <C-e>   :Explore<CR>
FnNoremap <silent> <C-A-e> :Vexplore<CR>

" Open netrw window
function! s:NetrwOpenWnd()
  Vexplore!
  let s:netrw_buf_num = bufnr("%")
endfunction

" Close netrw window
function! s:NetrwCloseWnd()
  if exists("s:netrw_buf_num")
    exec bufwinnr(s:netrw_buf_num) "wincmd c"
    unlet s:netrw_buf_num
  endif
endfunction


" *******************************************************
" } Cscope {
" *******************************************************

if has("cscope")
  " Option
  let g:cscope_db = !empty($CSCOPE_DB) ? $CSCOPE_DB : "cscope.out"
  if has('quickfix')
    set cscopequickfix=s-,c-,d-,i-,t-,e-
  endif

  " Cscope user command
  command! -nargs=* Cs :lcs <args>

  " Abbreviation
  cabbrev csa lcs add
  cabbrev csf lcs find
  cabbrev csk lcs kill
  cabbrev csr lcs reset
  cabbrev css lcs show
  cabbrev csh lcs help

  " Add any cscope database in the given environment variable
  "for db in add(split($CSCOPE_DB), g:cscope_db)
  "  if filereadable(db)
  "    silent! exe "cs add" db
  "  endif
  "endfor

  " Find and load cscope database
  function! s:LoadCscope()
    let db = findfile(g:cscope_db, ".;")
    if (filereadable(db))
      silent! exe "cs add" db matchstr(db, ".*/")
      "set nocscopeverbose " suppress 'duplicate connection' error
      "exe "cs add" db matchstr(db, ".*/")
      "set cscopeverbose
    endif
  endfunction

  " Additionnal keymap
  nnoremap <c-d><c-l>  :call <SID>LoadCscope()<CR>
  nnoremap <c-d>       <NOP>

  " Autocommand
  augroup vimrc_cscope
    autocmd! BufReadPost * call s:LoadCscope()
  augroup END
endif


" *******************************************************
" } Omnicompletion {
" *******************************************************
" Enable OmniCppComplete
"set omnifunc=cppcomplete#CompleteCPP
"filetype plugin on

" Enable vim completion
set omnifunc=syntaxcomplete#Complete
filetype plugin on

" Set completion options
set completeopt=longest,menuone

" Advanced key mapping to omnicompletion
function! s:CleverTab()
  if pumvisible()
    return "\<C-N>"
  endif
  if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
    return "\<Tab>"
  elseif exists('&omnifunc') && &omnifunc != ''
    return "\<C-X>\<C-O>"
  else
    return "\<C-N>"
  endif
endfunction

" Key mapping
"inoremap <C-space>  <C-x><C-o>
inoremap <C-space>  <C-R>=<SID>CleverTab()<CR>


" *******************************************************
" } Project plugin {
" *******************************************************
if !exists('g:loaded_project')
  " Options
  set nocompatible
  let g:proj_window_width = 22
  let g:proj_window_increment = 0
  let g:proj_flags = 'GS'
  let g:proj_window_pos = 'L'

  " Toggle ON/OFF
  nmap <localleader>j  :Project<CR>
endif


" *******************************************************
" } Taglist plugin {
" *******************************************************
if !exists('g:loaded_taglist')
  " Options
  if !exists('g:Tlist_Use_Right_Window')
    let g:Tlist_Use_Right_Window = 0    " Split to the right side of the screen
  endif
  let g:Tlist_WinWidth = 22             " Set the window width
  let g:Tlist_Sort_Type = "order"       " Sort by the "order" or "name"
  let g:Tlist_Compact_Format = 1        " Display the help info
  let g:Tlist_Exit_OnlyWindow = 1       " If you are the last, kill yourself
  let g:Tlist_File_Fold_Auto_Close = 1  " Close tags for other files
  let g:Tlist_Enable_Fold_Column = 0    " Show folding tree
  let g:Tlist_Show_One_File = 1         " Always display one file tags
  let g:Tlist_Display_Tag_Scope = 0     " Display tag scope (function/constants/variables)
  let g:Tlist_Use_SingleClick = 1       " Single click instead of double

  " Toggle ON/OFF
  nmap <localleader>t   :Tlist<CR>
  nmap <localleader>tt  :TlistClose<CR>
endif


" *******************************************************
" } SrcExplorer plugin {
" *******************************************************
if !exists('g:loaded_srcexpl')
  " Options
  let g:SrcExpl_winHeight = 8         " Set the height of Source Explorer window
  let g:SrcExpl_refreshTime = 100     " Set 100 ms for refreshing the Source Explorer
  let g:SrcExpl_jumpKey = "<ENTER>"       " Set key to jump into the exact definition context
  let g:SrcExpl_gobackKey = "<BACKSPACE>" " Set key for back from the definition context
  let g:SrcExpl_searchLocalDef = 0    " Enable/Disable the local definition searching (Warning: side effect Ctrl-O/I stop working)
  let g:SrcExpl_isUpdateTags = 0      " Tag update on file opening
  let g:SrcExpl_updateTagsCmd = ""    " Tag update command
  let g:SrcExpl_updateTagsKey = ""    " Tag update key
  let g:SrcExpl_prevDefKey = "<C-S-F5>" " Show prev definition in jump list
  let g:SrcExpl_nextDefKey = "<C-F5>"   " Show next definition in jump list
  let g:SrcExpl_pluginList = g:wndmgr_pluginList " Plugin names that are using buffers

  " Toggle ON/OFF
  nmap <localleader>s   :SrcExpl<CR>
  nmap <localleader>ss  :SrcExplClose<CR>
endif


" *******************************************************
" } NERDTree plugin {
" *******************************************************
if !exists('g:loaded_nerd_tree')
  " Options
  let g:NERDTreeWinSize = 25            " Set the window width
  let g:NERDTreeWinPos = "right"        " Set the window position
  let g:NERDTreeAutoCenter = 0          " Auto centre
  let g:NERDTreeHighlightCursorline = 0 " Not Highlight the cursor line

  " Toggle ON/OFF
  nmap <localleader>n   :NERDTree<CR>
  nmap <localleader>nn  :NERDTreeClose<CR>
endif


" *******************************************************
" } MiniBufExplorer plugin {
" *******************************************************
if !exists('g:loaded_minibufexplorer')
  " Options
  let g:miniBufExplStatusLineText = ""
  let g:miniBufExplBuffersNeeded = 2
  let g:miniBufExplUseSingleClick = 1
  let g:miniBufExplCycleArround = 1
  let g:miniBufExplShowBufNumbers = 1
  let g:miniBufExplAutoStart = 1
  let g:miniBufExplAutoUpdate = 1
  let g:miniBufExplSplitToEdge = 1
  let g:miniBufExplTabWrap = 1
  let g:miniBufExplMinSize = 1
  let g:miniBufExplMaxSize = 3
  let g:miniBufExplSortBy = 'number'
  let g:miniBufExplBRSplit = 0

  " Colors
  hi MBENormal               guifg=#FFFFFF guibg=bg
  hi MBEChanged              guifg='orange' guibg=bg
  hi MBEVisibleNormal        guifg=#FFFFFF guibg=bg
  hi MBEVisibleChanged       guifg='orange' guibg=bg
  hi MBEVisibleActiveNormal  guifg='cyan'  guibg=bg gui=bold,underline
  hi MBEVisibleActiveChanged guifg=#FF0000 guibg=bg

  " Toggle ON/OFF
  map <localleader>m        :MBEToggle<CR>

  " Overwrite open/close key mapping
  FnMap <C-b>c              :MBEbd<CR>

  " Cycle through buffers
  FnMap <A-Down>  :MBEbb<CR>
  FnMap <A-Up>    :MBEbf<CR>
  if !exists("g:vimrc_useTabs")
    "FnNoremap <C-Tab>      :MBEbb<CR>
    "FnNoremap <C-S-Tab>    :MBEbf<CR>
    FnNoremap <C-Tab>       :call <SID>MbeSwitch(1)<CR>
    FnNoremap <C-S-Tab>     :call <SID>MbeSwitch(0)<CR>
  endif

  " Switch between 2 buffers
  if !exists('s:vimrc_mbeswitch')
    let s:vimrc_mbeswitch = 0
  endif
  function! s:MbeSwitch(toggle)
    if a:toggle == 1
      let s:vimrc_mbeswitch = !s:vimrc_mbeswitch
    endif
    if s:vimrc_mbeswitch == 1
      MBEbb
    else
      MBEbf
    endif
  endfunction

endif


" *******************************************************
" } CCVext plugin {
" *******************************************************
if !exists('g:ccvext_version')
  " Options
  let g:ccvext_WndHeight = 10
  let g:ccvext_autostart = 0
  " Toggle ON/OFF
  nmap <localleader>c   :CCVext<CR>
  nmap <localleader>cc  :CCVextClose<CR>
endif


" *******************************************************
" } Yaifa plugin {
" *******************************************************
if !exists('g:loaded_yaifa')
  " Options
  let g:yaifa_max_lines=512
  " Map Yaifa
  nmap <localleader><tab>   :call YAIFA()<CR>
  " autocall when entering file
  augroup YAIFA
    autocmd! BufRead * silent! call YAIFA()
  augroup END
endif


" *******************************************************
" } Yankring plugin {
" *******************************************************
if !exists('g:loaded_yankring')
  " Options
  let g:yankring_v_key = ""
  let g:yankring_del_v_key = ""
  let g:yankring_paste_n_bkey = ""
  let g:yankring_paste_n_akey = ""
  let g:yankring_paste_v_bkey = ""
  let g:yankring_paste_v_akey = ""
  let g:yankring_replace_n_pkey = ""
  let g:yankring_replace_n_nkey = ""
endif


" *******************************************************
" } CCTree plugin {
" *******************************************************
if !exists('g:loaded_cctree')
  " Options
  let g:CCTreeCscopeDb = "cscope.out, $CSCOPE_DB"
  let g:CCTreeDisplayMode = 2
  let g:CCTreeRecursiveDepth = 3

  " Add any cscope database in the given environment variable
  for db in split(g:CCTreeCscopeDb)
    if filereadable(db)
      exec 'let g:CCTreeCscopeDb =' db
      break
    endif
  endfor

  " Key mappings
  let g:CCTreeKeyTraceReverseTree = '<localleader>x'
  let g:CCTreeKeyTraceForwardTree = '<localleader>xf'
  let g:CCTreeKeyToggleWindow = '<localleader>xx'
  nmap <localleader>xl      :if filereadable(g:CCTreeCscopeDb) <BAR> exec "CCTreeLoadDB" g:CCTreeCscopeDb <BAR> endif
  "nmap <localleader>xl     :if filereadable('xref.out') <BAR> CCTreeLoadXRefDbFromDisk xref.out <BAR> endif
endif


" *******************************************************
" } Command-T plugin {
" *******************************************************
if !exists('g:command_t_loaded')
  " Options
  let g:CommandTWildIgnore="*.o,*.obj,**/tmp/**"
  let g:CommandTMaxDepth = 8
  let g:CommandTMaxCachedDirectories = 2

  " Key mapping
  FnNoremap <C-p>     :CommandT<CR>
endif


" *******************************************************
" } CTRLP plugin {
" *******************************************************
if !exists('g:loaded_ctrlp')
  " Options
  let g:ctrlp_map = '<C-p>'
  let g:ctrlp_cmd = 'CtrlP'
  let g:ctrlp_working_path_mode = '0'
  let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.(git|hg|svn)|tmp)$',
  \ 'file': '\v\.(exe|so|dll|o)$'
  \ }
  " Key mapping
  FnNoremap <C-o>     :CtrlPMRU<CR>
endif


" *******************************************************
" } Tagbar plugin {
" *******************************************************
if !exists('g:loaded_tagbar')
  " Options
  let g:tagbar_left = 1
  let g:tagbar_width = 30
  let g:tagbar_autoshowtag = 0
  let g:tagbar_expand = 1
  let g:tagbar_indent = 1
  let g:tagbar_show_linenumbers = 0
  let g:tagbar_singleclick = 1
  let g:tagbar_sort = 0

  " VHDL support
  let g:tagbar_type_vhdl = {
    \ 'ctagstype': 'vhdl',
    \ 'kinds' : [
      \'d:prototypes',
      \'b:package bodies',
      \'e:entities',
      \'a:architectures',
      \'t:types',
      \'p:processes',
      \'f:functions',
      \'r:procedures',
      \'c:constants',
      \'T:subtypes',
      \'r:records',
      \'C:components',
      \'P:packages',
      \'l:locals'
    \]
  \}

  " Toggle ON/OFF
  nmap <localleader>t   :TagbarToggle<CR>
  nmap <localleader>tt  :TagbarClose<CR>
endif


" *******************************************************
" } buftabs plugin {
" *******************************************************
if !exists('g:loaded_buftabs')
  " Options
  let g:buftabs_only_basename = 1
  let g:buftabs_in_statusline = 1
  "let g:buftabs_marker_start = '[['
  "let g:buftabs_marker_end = ']]'
  let g:buftabs_separator = ":"
  "let g:buftabs_active_highlight_group="Visual"
endif


" *******************************************************
" } DirDiff plugin {
" *******************************************************
if !exists('g:loaded_dirdiff')
  " Options
  let g:DirDiffExcludes = "CVS,*.class,*.exe,.*.swp"  " Default exclude pattern
  let g:DirDiffIgnore = "Id:,Revision:,Date:"         " Default ignore pattern
  let g:DirDiffSort = 1                               " Sorts the diff lines
  let g:DirDiffWindowSize = 14                        " Diff window height
  let g:DirDiffIgnoreCase = 0                         " Ignore case during diff
  let g:DirDiffDynamicDiffText = 0                    " Dynamically figure out the diff text
  let g:DirDiffTextFiles = "Files "                   " Diff tool difference text
  let g:DirDiffTextAnd = " and "                      " Diff tool "and" text
  let g:DirDiffTextDiffer = " differ"                 " Diff tool "differ" text
  let g:DirDiffTextOnlyIn = "Only in "                " Diff tool "Only in" text

  " Key mapping
  nnoremap <silent><leader>d  :DirDiff\
endif


" *******************************************************
" } Easytags plugin {
" *******************************************************
if !exists('g:loaded_easytags')
  " Options
  let g:easytags_auto_update = 0          " Enable/disable tags auto-updating
  let g:easytags_dynamic_files = 1        " Use project tag file instead of ~/.vimtags
  let g:easytags_autorecurse = 0          " No recursion, update current file only
  let g:easytags_include_members = 1      " C++ include class members
  "let g:easytags_events = ['BufWritePost']" Update tags on events
  let g:easytags_updatetime_min = 30000   " Wait for few ms before updating tags
  let g:easytags_updatetime_warn = 0      " Disable warning when update-time is low
  let g:easytags_on_cursorhold = 1        " Update on cursor hold
endif


" *******************************************************
" } Hexadecimal display {
" *******************************************************
if !exists('g:vimrc_hexa')
  let g:vimrc_hexa=0
endif

function! s:HexaToggle()
  let g:vimrc_hexa=!g:vimrc_hexa
  if g:vimrc_hexa==1
    exec ":%!xxd"
  else
    exec ":%!xxd -r"
  endif
endfunction

" Key mapping
map <leader>h :call <SID>HexaToggle()<CR>


" *******************************************************
" } Sessions {
" *******************************************************
" Key mapping
FnNoremap <C-F9>      :mksession! ~/.vimsession <CR>
FnNoremap <F9>        :source! ~/.vimsession<CR>


" *******************************************************
" } Alignment function {
" *******************************************************
" Alignement function
function! s:AlignStatement()
  " Patterns needed to locate assignment operators...
  let ASSIGN_OP   = '[-+*/%|&]\?=\@<!=[=~]\@!'
  let ASSIGN_LINE = '^\(.\{-}\)\s*\(' . ASSIGN_OP . '\)'

  " Locate block of code to be considered (same indentation, no blanks)
  let indent_pat = '^' . matchstr(getline('.'), '^\s*') . '\S'
  let firstline  = search('^\%('. indent_pat . '\)\@!','bnW') + 1
  let lastline   = search('^\%('. indent_pat . '\)\@!', 'nW') - 1
  if lastline < 0
    let lastline = line('$')
  endif

  " Find the column at which the operators should be aligned...
  let max_align_col = 0
  let max_op_width  = 0
  for linetext in getline(firstline, lastline)
    " Does this line have an assignment in it?
    let left_width = match(linetext, '\s*' . ASSIGN_OP)

    " If so, track the maximal assignment column and operator width...
    if left_width >= 0
      let max_align_col = max([max_align_col, left_width])
      let op_width      = strlen(matchstr(linetext, ASSIGN_OP))
      let max_op_width  = max([max_op_width, op_width+1])
     endif
  endfor

  " Code needed to reformat lines so as to align operators...
  let FORMATTER = '\=printf("%-*s%*s", max_align_col, submatch(1),
  \                                    max_op_width,  submatch(2))'

  " Reformat lines with operators aligned in the appropriate column...
  for linenum in range(firstline, lastline)
    let oldline = getline(linenum)
    let newline = substitute(oldline, ASSIGN_LINE, FORMATTER, "")
    call setline(linenum, newline)
  endfor
endfunction

" User commands
command! -nargs=0 -bar AlignStatement      :call <SID>AlignStatement()

" Key mapping
map <leader>=   :AlignStatement<CR>


" *******************************************************
" } Inline increment/decrement function {
" *******************************************************

" Increment/decrement numbers
FnNoremap <A-a>   <C-a>
FnNoremap <A-A>   <C-x>


" *******************************************************
" } Environment conclusion {
" *******************************************************

" Use after config
if filereadable(expand("~/.vimrc.after"))
  source ~/.vimrc.after
endif

" Security
set secure
set noexrc

" Load flag
let g:loaded_vimrc = 1

" }

