" XDG Environment For VIM
" =======================
" Source
" ----------
" - https://gist.github.com/kaleb/3885679
" - https://github.com/kaleb/vim-files/blob/master/xdg.vim
"
" References
" ----------
" - http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables
" - http://tlvince.com/vim-respect-xdg
"

" Environment directories
if empty($XDG_CACHE_HOME)
	let $XDG_CACHE_HOME = expand("$HOME") . '/.cache'
endif
if empty($XDG_CONFIG_HOME)
	let $XDG_CONFIG_HOME = expand("$HOME") . '/.config'
endif

" Create environment directories
if !isdirectory($XDG_CACHE_HOME . "/vim/swap")
	call mkdir($XDG_CACHE_HOME . "/vim/swap", "p")
endif
if !isdirectory($XDG_CACHE_HOME . "/vim/backup")
	call mkdir($XDG_CACHE_HOME . "/vim/backup", "p")
endif
if !isdirectory($XDG_CACHE_HOME . "/vim/undo")
	call mkdir($XDG_CACHE_HOME . "/vim/undo", "p")
endif

" Setup vim cache directories
set directory=$XDG_CACHE_HOME/vim/swap//,/var/tmp//,/tmp//
set backupdir=$XDG_CACHE_HOME/vim/backup//,/var/tmp//,/tmp//
set undodir=$XDG_CACHE_HOME/vim/undo//,/var/tmp//,/tmp//
set viewdir=$XDG_CACHE_HOME/vim/view//

" Setup vim runpath directory
set runtimepath-=$HOME/.vim
set runtimepath-=$HOME/.vim/after
set runtimepath^=$XDG_CONFIG_HOME/vim
set runtimepath+=$XDG_CONFIG_HOME/vim/after

" Setup vim persistence config
" see :help persistent-undo
set viminfo='10,\"100,:20,n$XDG_CACHE_HOME/vim/viminfo
set undofile

" Double slash does not actually work for backupdir, here's a fix
au BufWritePre * let &backupext='@'.substitute(substitute(substitute(expand('%:p:h'), '/', '%', 'g'), '\', '%', 'g'), ':', '', 'g')

" Load .vimrc
"source $XDG_CONFIG_HOME/vim/.vimrc
"source ~/.vimrc
