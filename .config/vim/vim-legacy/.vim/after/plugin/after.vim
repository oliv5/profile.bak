" Load the final user scripts

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
" } The end
" *******************************************************

" Load flag
let g:loaded_vimrc = 1
