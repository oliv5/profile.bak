" Rebuild tag file
let s:vimrc_updateTagsCmd = "ctags --fields=+iaS --extra=+q --sort=foldcase -R ."
map <leader>t :call <SID>Vimrc_UpdateTags()<CR>

" Update tags file with the 'ctags' utility
function! s:Vimrc_UpdateTags() abort
  " Go to the current work directory
  silent! exe "cd " . expand('%:p:h')
  " Get the amount of all files named 'tags'
  let l:tmp = len(tagfiles())
  " No tags file or not found one
  if l:tmp == 0

    " Ask user if or not create a tags file
    echohl Question
      call inputsave()
      let l:tmp = input("\nTags: "
        \ . "The 'tags' file was not found in your PATH.\n"
        \ . "Create one in the current directory now? (y)es/(n)o? ")
      call inputrestore()
    echohl None
    echo "\n"

    " Yes
    if l:tmp == "y" || l:tmp == "yes"

      " Tell user where we create a tags file
      echohl Question
        echo "Tags: Creating 'tags' file in (". expand('%:p:h') . ")"
      echohl None
      " Call the external 'ctags' utility program
      exe "!" . s:vimrc_updateTagsCmd
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
      exe "!" . s:vimrc_updateTagsCmd
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
      exe "!" . s:vimrc_updateTagsCmd
       " Go back to the original work directory
       silent! exe "cd " . l:tmp
    endif

  endif
  return 0
endfunction
