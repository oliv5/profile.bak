" Vim syntax file for ZSP logs
" See http://vim.wikia.com/wiki/Creating_your_own_syntax_files
if exists("b:current_syntax")
    finish
endif
let b:current_syntax="zsplog"

" Clear everything
syntax clear

" Define keywords
syn keyword             fatal 	ASSERT FAILING

" Define Matches
syn match		preamble    /^.*\].*\]/
syn match               value       /\d\+/ contained
syn match               arg         / = \d\+/ contains=value contained

syn match		testLog     /[^\]]*Test log\. / nextgroup=testParam
syn match		testParam    /\(param\d\+ = \d\+,\= \=\)\+/ contains=arg

syn match		crpCommit   /[^\]]*CRP command\..*$/
syn match		crpComplete /[^\]]*CRP command complete\..*$/

syn match		fftIrq      /[^\]]*IRQ SET \d\+.*$/
syn match		fftSymbol   /[^\]]*FFT symbol.*$/ contains=arg

syn match		subframe    /[^\]]*New subframe.*$/

"syn match		logCache    /^.*LOG CACHE DUMP\_.*LOG CACHE DUMP.*$/
syn match		logCache    /^.*LOG CACHE DUMP.*$/
syn match		fatal       /^.*ASSERT.*$/

" Define regions
"syn region syntaxElementRegion start='x' end='y'

" Define formatting & colors
hi link preamble        Normal
hi link value           WarningMsg

hi link testLog         Title
hi link testParam       Title

hi link fatal	        Error
hi link logCache	WarningMsg

hi link crpCommit	Comment
hi link crpComplete	Comment

hi link fftIrq	        Preproc
hi link fftSymbol       Special

" Enable/disable case sensitivity locally
"syn case ignore
"syn case match

