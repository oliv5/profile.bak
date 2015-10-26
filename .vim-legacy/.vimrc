" Notes {
" Based on Smylers's .vimrc
" 2000 Jun  1: for `Vim' 5.6
" Reworked by Oliv5
"
" Hints
" <C-C> goto normal mode
" <C-O> stay in insert mode to execute a single cmd
"
" Toggle key maps: <localleader>
" Action key maps: <leader>
"
" Resources
" Vim refcards: http://tnerual.eriogerg.free.fr/vim.html
" Vim tips: http://www.rayninfo.co.uk/vimtips.html

" *******************************************************
" } Environment preamble {
" *******************************************************

" Version check
if v:version < 700
	echoe ".vimrc requires VIM 7.0 or above"
	finish
endif

" User commands check
if !exists("g:reload_vimrc")
	if !has('user_commands') || !has('autocmd') || !has('gui')
		" Reload .vimrc silently (removes autocommands errors)
		let g:reload_vimrc = 1
		silent! source $MYVIMRC
		finish
	endif
endif

" Security
set secure
set noexrc

" Leader key mappings
let mapleader = ";"         " Leader key
let maplocalleader = ","    " Local leader key


" *******************************************************
" } Before scripts {
" *******************************************************

" Use before config
if filereadable(expand("~/.vimrc.before"))
	source ~/.vimrc.before
endif
if filereadable(expand("~/.vimrc.before.local"))
	source ~/.vimrc.before.local
endif


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

" Autoreload changed files
set noautoread

" File ignore
"set wildignore+=**/.snv/**,**/.git/**,**/tmp/**,*.so,*.o,*.dll,*.a,*.tmp

" Autochange directory
let g:vimrc_autochdir = 2


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
if has('syntax')
	syntax on     " Syntax highlight
	" Color scheme
	if (&term=="builtin_gui" || has("gui_running") || &t_Co>2)
		colorscheme torte
	else
		colorscheme default
	endif
	" Completion menu
	highlight Pmenu gui=bold guifg=black guibg=brown ctermfg=0 ctermbg=238
	highlight PmenuSel gui=bold guifg=black guibg=grey ctermfg=0 ctermbg=238
endif

" Select font
if !exists('g:loaded_vimrc')
	"set guifont=Lucida_Console:h11
	set guifont=Monospace\ 9
endif

" Gui options
set guioptions-=T     " Remove toolbar
set guioptions+=aA    " Enable autoselect (autocopy)

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
set whichwrap=h,l,~,[,]   " Wrap between lines for h, l, ~, cursor keys [ and ]
set matchpairs+=<:>   " '%' bounce between brackets

" Backspace delete line breaks, over the start of the
" current insertion, and over indentations
set backspace=indent,eol,start

" Save/restore part of edit session
"  /10  :  search items
"  '10  :  marks in 10 previously edited files
"  r/mnt/zip,r/mnt/floppy : excluded locations
"  "100 :  100 lines for each register
"  :20  :  20 lines of command-line history
"  %    :  buffer list
"  n... :  viminfo file location
set viminfo='10,\"100,:20,n~/.vimdata/viminfo

" Set directories
set backupdir=~/.vimdata/vimbackup
set viewdir=~/.vimdata/vimview
set directory=~/.vimdata/vimswap
set undodir=~/.vimdata/vimundo

" When using list, keep tabs at their full width and display `arrows':
" (Character 187 is a right double-chevron, and 183 a mid-dot.)
execute 'set listchars+=tab:' . nr2char(187) . nr2char(183)

" Jump to the last cursor position
augroup vimrc_cursor_lastpos
	autocmd! BufReadPost *
		\ if line("'\"") > 0 && line ("'\"") <= line("$") |
		\   exe "normal! g'\"" |
		\ endif
augroup END


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
" } Load plugins {
" *******************************************************
" Disable unused plugins
let g:loaded_bbye = 1
let g:loaded_project = 1
let g:loaded_taglist = 1
"let g:loaded_tagbar = 1
let g:loaded_srcexpl = 1
let g:loaded_nerd_tree = 1
let g:loaded_trinity = 1
let g:ccvext_version = 1
let g:loaded_yankring = 1
let g:loaded_cctree = 1
let g:command_t_loaded = 1
"let g:loaded_minibufexplorer = 1
"let g:loaded_yaifa = 1
"let g:loaded_ctrlp = 1
"let g:loaded_buftabs = 1
let g:loaded_easytags = 1
let g:c_complete_loaded = 1
let g:syntax_complete_loaded = 1
"let g:omnicpp_complete_loaded = 1
let g:clang_complete_loaded = 1
"let g:loaded_commentary = 1
let g:loaded_bufline = 1

" Load bundles config
if filereadable(expand("~/.vimrc.bundles"))
	source ~/.vimrc.bundles
endif
if filereadable(expand("~/.vimrc.bundles.local"))
	source ~/.vimrc.bundles.local
endif

" Load plugins with pathogen
filetype off                " force reloading *after* pathogen loaded
runtime bundle/pathogen/autoload/pathogen.vim
execute pathogen#infect()
filetype plugin indent on   " enable detection, plugins and indenting in one step


" *******************************************************
" } After scripts {
" *******************************************************

" Use after config
if filereadable(expand("~/.vimrc.after"))
	source ~/.vimrc.after
endif
if filereadable(expand("~/.vimrc.after.local"))
	source ~/.vimrc.after.local
endif


" *******************************************************
" } Environment conclusion {
" *******************************************************

" Load flag
let g:loaded_vimrc = 1


" *******************************************************
" } The end
" *******************************************************
