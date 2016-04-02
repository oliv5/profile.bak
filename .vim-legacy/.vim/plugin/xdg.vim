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

" Setup few variables
if empty($XDG_CACHE_HOME)
  let $XDG_CACHE_HOME = '~/.cache'
endif
if empty($XDG_CONFIG_HOME)
  let $XDG_CONFIG_HOME = '~/.config'
endif

" Create directories
if !isdirectory($XDG_CACHE_HOME . "/vim/swap")
  call mkdir($XDG_CACHE_HOME . "/vim/swap", "p")
endif
if !isdirectory($XDG_CACHE_HOME . "/vim/backup")
  call mkdir($XDG_CACHE_HOME . "/vim/backup", "p")
endif
if !isdirectory($XDG_CACHE_HOME . "/vim/undo")
  call mkdir($XDG_CACHE_HOME . "/vim/undo", "p")
endif

" Setup vim runpath directories
set directory=$XDG_CACHE_HOME/vim/swap//,/var/tmp//,/tmp//
set backupdir=$XDG_CACHE_HOME/vim/backup//,/var/tmp//,/tmp//
set undodir=$XDG_CACHE_HOME/vim/undo//,/var/tmp//,/tmp//
set viminfo+=$XDG_CACHE_HOME/vim/viminfo
set runtimepath-=~/.vim
set runtimepath-=~/.vim/after
set runtimepath^=$XDG_CONFIG_HOME/vim
set runtimepath+=$XDG_CONFIG_HOME/vim/after

" see :help persistent-undo
set undofile

" Double slash does not actually work for backupdir, here's a fix
au BufWritePre * let &backupext='@'.substitute(substitute(substitute(expand('%:p:h'), '/', '%', 'g'), '\', '%', 'g'), ':', '', 'g')
