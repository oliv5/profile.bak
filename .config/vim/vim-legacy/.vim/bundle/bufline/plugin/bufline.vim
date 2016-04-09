"---------------------------------------------------------------------------
"  File:          bufline.vim
"  Version:       1.0
"  Last Modified: 2014-05-19
"  Maintainer:    Gleevoy Valentin AKA SbT < gleevoy at gmail dot com >
"
"---------------------------------------------------------------------------
"
"  Copyright © 2014, Gleevoy Valentin AKA SbT
"  All rights reserved.
"
"  Redistribution and use in source and binary forms, with or without
"  modification, are permitted provided that the following conditions are
"  met:
"   * Redistributions of source code must retain the above copyright
"     notice, this list of conditions and the following disclaimer.
"   * Redistributions in binary form must reproduce the above copyright
"     notice, this list of conditions and the following disclaimer in the
"     documentation and/or other materials provided with the distribution.
"   * Neither the name of the script author nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission.
"
"  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"  'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
"  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
"  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER BE
"  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
"  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
"  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
"  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
"  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
"  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
"  THE POSSIBILITY OF SUCH DAMAGE.
"
"---------------------------------------------------------------------------

" Already loaded ?
if exists("g:loaded_bufline")
  finish
endif
let g:loaded_bufline = 1


"  == Script locals. == {{{

let s:first_index = 1

let s:buffer_filter = '.*'

let s:buffer_filter_case = s:buffer_filter

let s:filter_stack = []

let s:last_modified = 0

let s:filter_list_empty = 0

let s:just_deleted = []

let s:disable_refresh = 0

"  }}}

"  == Settings. ==   {{{

"  Initializes a global variable unless it is already defined.
function! s:Init(name, value) "  {{{
   let l:fullname = 'g:bufline_' . a:name
   if (!exists(l:fullname))
      execute 'let ' . l:fullname . '=' . a:value
   endif
endfunction
"  }}}

"  Returns a value of a global variable.
function! s:Setting(name)  "  {{{
   let l:fullname = 'g:bufline_' . a:name
   execute 'return ' . l:fullname
endfunction
"  }}}

"  Loads all settings into script local variables.
function! s:ReloadSettings()  "  {{{
   let s:left_arrow = s:Setting('left_arrow')
   let s:right_arrow = s:Setting('right_arrow')
   let s:arrows_placement = s:Setting('arrows_placement')
   let s:show_inactive_arrows = s:Setting('show_inactive_arrows')
   let s:modified_sign = s:Setting('modified_sign')
   let s:default_filter = s:Setting('default_filter')
   let s:show_filter = s:Setting('show_filter')
   let s:filtering = s:Setting('filtering')
   let s:autoscroll = s:Setting('autoscroll')
   let s:bufname_maxlength = s:Setting('bufname_maxlength')
   let s:case_sensitivity = s:Setting('case_sensitivity')

   let l:case_sensitive = 1

   if (s:case_sensitivity == 0)
      if (has('win16') || has('win32') || has('win64'))
         let l:case_sensitive = 0
      endif
   elseif (s:case_sensitivity == 2)
      let l:case_sensitive = 0
   endif

   let s:buffer_filter_case = s:buffer_filter
   if (l:case_sensitive == 0)
      let s:buffer_filter_case = s:buffer_filter_case . '\c'
   endif

endfunction
"  }}}

call s:Init('left_arrow', "' ◀ '")
call s:Init('right_arrow', "' ▶ '")
call s:Init('arrows_placement', "0")
call s:Init('show_inactive_arrows', "0")
call s:Init('modified_sign', "''")
call s:Init('default_filter', "'.*'")
call s:Init('show_filter', "1")
call s:Init('filtering', "1")
call s:Init('autoscroll', "1")
call s:Init('bufname_maxlength', "0")
call s:Init('case_sensitivity', "0")

call s:ReloadSettings()

"  }}}

"  == Default mappings. == {{{
function! s:AddMapping(mapping, fun)
   execute 'nnoremap <silent> ' . s:mapping_prefix . a:mapping . ' :call ' . a:fun . '<CR>'
endfunction

function! BufLine_InitializeMappings(prefix)
   let s:mapping_prefix = a:prefix
   call s:AddMapping('f', 'BufLine_AddFilter(input("Filter: "))')
   call s:AddMapping('F', 'BufLine_SetFilter(input("Filter: "))')
   call s:AddMapping('e', 'BufLine_FilterFromCurExt()')
   call s:AddMapping('E', 'BufLine_FilterFromExt(input("Extension: "))')
   call s:AddMapping('n', 'BufLine_FilterFromCurPath()')
   call s:AddMapping('d', 'BufLine_SetDefaultFilter()')
   call s:AddMapping('p', 'BufLine_PushFilter()')
   call s:AddMapping('P', 'BufLine_PopFilter()')
   call s:AddMapping('t', 'BufLine_ToggleFiltering()')
   call s:AddMapping('s', 'BufLine_CycleSensitivity()')
   call s:AddMapping('h', 'BufLine_ScrollLeft()')
   call s:AddMapping('l', 'BufLine_ScrollRight()')
endfunction
"  }}}

"  == Necessary VIM adjustments. == {{{

"  Disable the GUI tabline for GVIM. Otherwise, the text tabline will not be
"  shown.
set guioptions-=e

"  Make the text tabline always displayed on the screen.
set showtabline=2

"  }}}

"  == Auto-commands. == {{{

augroup BufLineAutoCommands

   autocmd!

   autocmd BufDelete * call s:BufferDeleted(str2nr(expand("<abuf>")))

   autocmd BufWinEnter,VimResized * call s:Autoscroll()

   autocmd BufWinEnter * call s:FilterEmptyCheck()

   autocmd TextChanged,CursorMovedI * call s:MaybeModified()

augroup END

"  If the current buffer was deleted, scroll to the next one if available.
"  Otherwise, scroll to previous.
function! s:BufferDeleted(nr) "  {{{
   let s:disable_refresh = s:disable_refresh + 1
   if (a:nr == s:first_index)
      call BufLine_ScrollRight()
      if (a:nr == s:first_index)
         call BufLine_ScrollLeft()
         if (a:nr == s:first_index)
            let s:first_index = 1
         endif
      endif
   endif

   call add(s:just_deleted, a:nr)
   call s:Show()
   let s:disable_refresh = s:disable_refresh - 1
   if (a:nr != winbufnr('.'))
      call s:Refresh()
   endif
endfunction
"  }}}

"  Update the first_index according to current autoscroll setting.
function! s:Autoscroll()   "  {{{
   call s:ReloadSettings()
   call s:Show()
   call s:Refresh()
endfunction
"  }}}

"  Check if the files modified flag is different from the last update.
function! s:MaybeModified()   "  {{{
   if (getbufvar(winbufnr('.'), '&modified') != s:last_modified)
      call s:Refresh()
   endif
endfunction
"  }}}

"  If the last filtering condition filtered away all buffers, and a new buffer
"  is opened that matches the filter, move first_index to it.
function! s:FilterEmptyCheck()   "  {{{
   let l:current = winbufnr('.')
   if (s:filter_list_empty && s:BufferIsFine(l:current))
      let s:filter_list_empty = 0
      let s:first_index = l:current
      call s:Show()
      call s:Refresh()
   endif
endfunction
"  }}}

"  }}}

"  == Functions. == {{{

"  Registers all the highlight groups.
function! s:RegisterHi()   "  {{{
   if (&bg == 'light')
      hi def BufLineHidden             ctermfg=DarkGray guifg=#303030 term=italic gui=italic
      hi def BufLineInactive           ctermfg=DarkGray guifg=#101010
      hi def BufLineActive             ctermfg=Black guifg=#000000 term=bold gui=bold
      hi def BufLineHiddenModified     ctermfg=DarkRed guifg=#602020 term=italic gui=italic
      hi def BufLineInactiveModified   ctermfg=DarkRed guifg=#802020
      hi def BufLineActiveModified     ctermfg=Red guifg=#800000 term=bold gui=bold
      hi def BufLineFilter             ctermfg=Black guifg=#000000 guibg=#C0C0C0
      hi def BufLineFilterDisabled     ctermfg=LightGray guifg=#E0E0E0
      hi def BufLineArrow              ctermfg=Black guifg=#000000 term=bold gui=bold
      hi def BufLineArrowInactive      ctermfg=LightGray guifg=#E0E0E0
   else
      hi def BufLineHidden             ctermfg=DarkGreen guifg=#008000 term=italic gui=italic
      hi def BufLineInactive           ctermfg=DarkGreen guifg=#00B000
      hi def BufLineActive             ctermfg=Green guifg=#00FF00 term=bold gui=bold
      hi def BufLineHiddenModified     ctermfg=DarkYellow guifg=#808000 term=italic gui=italic
      hi def BufLineInactiveModified   ctermfg=DarkYellow guifg=#B0B000
      hi def BufLineActiveModified     ctermfg=Yellow guifg=#FFFF00 term=bold gui=bold
      hi def BufLineFilter             ctermfg=Green ctermbg=DarkGray guifg=#00FF00 guibg=#303030
      hi def BufLineFilterDisabled     ctermfg=DarkGreen guifg=#002000
      hi def BufLineArrow              ctermfg=Green guifg=#00FF00 term=bold gui=bold
      hi def BufLineArrowInactive      ctermfg=DarkGreen guifg=#002000
   endif
endfunction
"  }}}

"  Checks if the buffer with a specified number should be output onto the
"  screen.
function! s:BufferIsFine(nr)  " {{{

   "  Only output buffer if it is listed, e.g. not hidden or removed.
   if(getbufvar(a:nr, '&buflisted') == 1)

      "  Check if the buffer was just removed.
      if (count(s:just_deleted, a:nr))
         return 0
      endif

      let l:bufname = fnamemodify(bufname(a:nr), ':p')

      "  Check the full file name against the current filter.
      if (!s:filtering || match(l:bufname, s:buffer_filter_case) != -1)
         return 1
      endif
   endif

   return 0

endfunction
"  }}}

"  Checks if the buffer is a first valid buffer.
function! s:BufferIsFirst(nr) " {{{
   let l:i = a:nr
   while (l:i > 1)
      let l:i = l:i - 1
      if (s:BufferIsFine(l:i))
         return 0
      endif
   endwhile
   return 1
endfunction
"  }}}

"  Checks if the buffer is a last valid buffer.
function! s:BufferIsLast(nr) " {{{
   let l:nbuffers = bufnr('$')
   let l:i = a:nr
   while (l:i < l:nbuffers)
      let l:i = l:i + 1
      if (s:BufferIsFine(l:i))
         return 0
      endif
   endwhile
   return 1
endfunction
"  }}}

"  Compute the displayed string and highlight group for a particular buffer.
function! s:BufferString(nr)  "  {{{

   if (a:nr < 1)
      return ['', '']

   elseif (s:BufferIsFine(a:nr))

      "  Get the full name of the buffer. Assumed to be a name of the
      "  associated file.
      let l:bufname = fnamemodify(bufname(a:nr), ':p')

      "  Extract file name without extension and extension separately.
      let l:filename = fnamemodify(l:bufname, ':t:r')
      let l:fileext = fnamemodify(l:bufname, ':e')

      "  Reduce the filename, if necessary.
      if (s:bufname_maxlength > 0 && strlen(l:filename) > s:bufname_maxlength)
         let l:filename = strpart(l:filename, 0, s:bufname_maxlength - 2) . '..'
      endif

      "  If a file name has extension, prepend period to it.
      if (strlen(l:fileext) > 0)
         let l:fileext = '.' . l:fileext
      endif

      "  If the file was modified, display '+' next to it.
      let l:modified = ''
      let l:modified_group = ''
      if (getbufvar(a:nr, '&modified') == 1)
         let l:modified = s:modified_sign
         let l:modified_group = 'Modified'
      endif

      "  Choose the current element style.
      let l:style = ""

         "  for buffer displayed in current split
      if (a:nr == winbufnr('.'))
         let l:style = 'BufLineActive' . l:modified_group
      else

         "  for buffer that is currently not displayed anywhere
         if (bufwinnr(a:nr) == -1)
            let l:style = 'BufLineHidden' . l:modified_group

         "  for buffer displayed elsewhere
         else
            let l:style = 'BufLineInactive' . l:modified_group
         endif
      endif

      "  See if we still fit in columns number.
      let l:element = '[' . a:nr . ':' . l:filename . l:fileext . ']' . l:modified

      return [l:element, l:style]
      
   else
      return ['', '']

   endif

endfunction
"  }}}

"  See if a given buffer is displayed in the tabline.
function! s:IsShown(nr) "  {{{
   if (a:nr < s:first_index)
      return 0
   else
      let l:nbuffers = bufnr('$')
      let l:i = s:first_index
      let l:columns = &columns
      let l:cols_used = strlen(s:left_arrow) + strlen(s:right_arrow)
      while (l:i <= l:nbuffers)
         let l:string = s:BufferString(l:i)
         let l:cols_used = l:cols_used + strlen(l:string[0])
         if (l:cols_used >= l:columns)
            return 0
         endif
         if (l:i == a:nr)
            return 1
         endif
         let l:i = l:i + 1
      endwhile
      return 0
   endif
endfunction "  }}}

"  Make sure the current buffer is shown in the tabline.
function! s:Show()   "  {{{
   let l:current = winbufnr('.')
   if (s:autoscroll && !s:IsShown(l:current) && s:BufferIsFine(l:current))

      if (l:current < s:first_index)
         let s:first_index = l:current
      else
         call s:ShowLast(l:current)
      endif

   endif
endfunction
"  }}}

"  Adjust the first_index such that a given buffer will be displayed last.
function! s:ShowLast(nr)   "  {{{
   let l:i = a:nr
   let l:columns = &columns
   let l:cols_used = strlen(s:left_arrow) + strlen(s:right_arrow)
   while (1)
      let l:string = s:BufferString(l:i)
      let l:cols_used = l:cols_used + strlen(l:string[0])
      if (l:cols_used > l:columns)
         return
      endif

      if (strlen(l:string[0]) > 0)
         let s:first_index = l:i
      endif
      let l:i = l:i - 1
   endwhile
endfunction
"  }}}

"  Returns the text that should be rendered in the tabline.
function! s:ListBuffers()  "  {{{
   let l:new_list = []
   for item in s:just_deleted
      if (s:BufferIsFine(item))
         add(l:new_list, item)
      endif
   endfor
   let s:just_deleted = l:new_list

   let l:nbuffers = bufnr('$')
   let l:current = winbufnr('.')
   let l:i = s:first_index
   let l:result = []
   let l:columns = &columns
   let l:cols_used = strlen(s:left_arrow) + strlen(s:right_arrow)
   let l:show_right_arrow = 0
   let l:prefix = ''
   let l:suffix = ''
   let l:is_first = s:BufferIsFirst(s:first_index)

   call s:RegisterHi()

   let l:inactive_group = ''
   if (l:is_first)
      let l:inactive_group = 'Inactive'
   endif

   if (!l:is_first || s:show_inactive_arrows)
      if (s:arrows_placement == 2)
         let l:suffix = '%#BufLineArrow' . l:inactive_group . '#' . s:left_arrow
      else
         let l:prefix = '%#BufLineArrow' . l:inactive_group . '#' . s:left_arrow
      endif
   endif

   "  For every buffer number used.
   while (l:i <= l:nbuffers)

      let l:string = s:BufferString(l:i)
      
      if (strlen(l:string[0]))

         "  See if we still fit in columns number.
         let l:cols_used = l:cols_used + strlen(l:string[0])
         if (l:cols_used > l:columns)
            let l:show_right_arrow = 1
            break
         endif
         call add(l:result, '%#'. l:string[1] . '#' . l:string[0])

      endif

      let l:i = l:i + 1

   endwhile

   let l:inactive_group = ''
   if (!l:show_right_arrow && s:show_inactive_arrows)
      let l:inactive_group = 'Inactive'
      let l:show_right_arrow = 1
   endif

   if (l:show_right_arrow)
      if (s:arrows_placement == 1)
         let l:prefix = l:prefix . '%#BufLineArrow' . l:inactive_group . '#' . s:right_arrow
      else
         let l:suffix = l:suffix . '%#BufLineArrow' . l:inactive_group . '#' . s:right_arrow
      endif
   endif

   "  Prepend a filter patter if any.
   let l:disabled_group = ''
   if (!s:filtering)
      let l:disabled_group = 'Disabled'
   endif
   let l:pattern = ''
   if (s:show_filter == 2 || (s:show_filter == 1 && s:buffer_filter != '.*'))
      let l:pattern = '%#BufLineFilter' . l:disabled_group . '#' . s:buffer_filter . ':'
   endif

   let l:resulting_string = l:pattern . l:prefix . join(l:result, '') . l:suffix . '%#BufLineHidden#'
   return l:resulting_string
endfunction

"  }}}

"  Refresh the tabline.
function! s:Refresh()   "  {{{
   if (s:disable_refresh == 0)
      execute "set tabline=" . escape(s:ListBuffers(), ' \')
      let s:last_modified = getbufvar(winbufnr('.'), '&modified')

   endif
endfunction
"  }}}

"  Changes the current buffer filter pattern.
function! BufLine_SetFilter(filter) " {{{
   let s:buffer_filter = a:filter
   if (has('win16') || has('win32') || has('win64'))
      let s:buffer_filter = s:buffer_filter . '\c'
   endif

   "  If the filter invalidated currently first buffer, try to scroll right
   let s:disable_refresh = s:disable_refresh + 1
   if (!s:BufferIsFine(s:first_index))
      call BufLine_ScrollRight()

      "  If unsuccessful, try left
      if (!s:BufferIsFine(s:first_index))
         call BufLine_ScrollLeft()

         "  Otherwise, we've filtered out all the buffers, just set index to 1
         if (!s:BufferIsFine(s:first_index))
            let s:first_index = 0
            let s:filter_list_empty = 1
         endif
         
      else
         let s:filter_list_empty = 0
      endif
   else
      let s:filter_list_empty = 0
   endif
   call s:Autoscroll()
   let s:disable_refresh = s:disable_refresh - 1
   call s:Refresh()
endfunction
"  }}}

"  Straightens the filtering condition with a new pattern.
function! BufLine_AddFilter(filter) " {{{
   if (s:buffer_filter == '.*')
      call BufLine_SetFilter(a:filter)
   else
      call BufLine_SetFilter(s:buffer_filter . '\&' . a:filter)
   endif
endfunction
"  }}}

"  Removes current buffer filters.
function! BufLine_SetDefaultFilter()   " {{{
   call BufLine_SetFilter(s:default_filter)
endfunction
"  }}}

"  Adds a pattern that filters out all file extensions but provided.
function! BufLine_FilterFromExt(ext)   " {{{
   call BufLine_AddFilter('.*\.' . a:ext . '$')
endfunction
"  }}}

"  Adds a filter based on the current files extension.
function! BufLine_FilterFromCurExt()  " {{{
   let l:ext = fnamemodify(bufname(winbufnr(".")), ":e")
   if (strlen(l:ext) > 0)
      call BufLine_FilterFromExt(l:ext)
   endif
endfunction
"  }}}

"  Adds a filter that only shows buffers that correspond to files located in
"  the subdirectory of the current files directory.
function! BufLine_FilterFromCurPath() "  {{{
   let l:path = fnamemodify(bufname(winbufnr(".")), ":p:h")
   if (strlen(l:path) > 0)
      call BufLine_AddFilter(l:path.'/.*')
   endif
endfunction
"  }}}

"  Scroll the tabline one element to the left if possible.
function! BufLine_ScrollLeft()  "  {{{
   call s:ReloadSettings()

   let l:i = s:first_index
   while (l:i > 1)
      let l:i = l:i - 1
      if (s:BufferIsFine(l:i))
         let s:first_index = l:i
         call s:Show()
         call s:Refresh()
         return
      endif
   endwhile

endfunction
"  }}}

"  Scroll the tabline one element to the right if possible.
function! BufLine_ScrollRight()  "  {{{
   call s:ReloadSettings()

   let l:nbuffers = bufnr('$')
   let l:i = s:first_index
   while (l:i < l:nbuffers)
      let l:i = l:i + 1
      if (s:BufferIsFine(l:i))
         let s:first_index = l:i
         call s:Show()
         call s:Refresh()
         return
      endif
   endwhile

endfunction
"  }}}

"  Push current filter on top of filter stack.
function! BufLine_PushFilter()   "  {{{
   let s:filter_stack = add(s:filter_stack, s:buffer_filter)
endfunction
"  }}}

"  Remove the filter from the top of the stack an make it current.
function! BufLine_PopFilter() "  {{{
   if (len(s:filter_stack) == 0)
      throw "filter stack underflow."
   endif
   let s:buffer_filter = remove(s:filter_stack, -1)
   call s:Refresh()
endfunction
"  }}}

"  Set a new value for a script global variable and redraw the tabline.
function! BufLine_SetSetting(name, value) "  {{{
   if (strlen(a:name) > 0)
      let l:value = a:value
      if (type(l:value) == 1)
         let l:value = '"' . l:value . '"'
      endif
      execute 'let' 'g:bufline_' . a:name ' = ' l:value
   endif
   call s:ReloadSettings()
   call s:Refresh()
endfunction
"  }}}

"  Toggle the filtering setting.
function! BufLine_ToggleFiltering() "  {{{
   let l:filtering = s:Setting('filtering')
   if (l:filtering)
      let l:filtering = 0
   else
      let l:filtering = 1
   endif
   call BufLine_SetSetting('filtering', l:filtering)
endfunction
"  }}}

"  Cycle through three case sensitivity options.
function! BufLine_CycleSensitivity()   "  {{{
   let l:sens = s:Setting('case_sensitivity') + 1
   if (l:sens > 2)
      let l:sens = 0
   endif
   call BufLine_SetSetting('case_sensitivity', l:sens)
endfunction
"  }}}

"  }}}

