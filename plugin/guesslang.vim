if !executable('aspell')
  echoerr 'GuessLang: please install ASPELL'
endif

if !exists('g:guesslang_langs')
  echoerr 'GuessLang: please add "let g:guesslang_langs = [ ''en'', ... ]" to .vimrc'
  let g:guesslang_langs = []
endif

if !exists('g:guesslang_lines')     | let g:guesslang_lines = 20     | endif
if !exists('g:guesslang_threshold') | let g:guesslang_threshold = 20 | endif

augroup GuessLang
  autocmd!
  if exists('##OptionSet')
    autocmd OptionSet spelllang
          \ let b:guesslang_explicit = 1 |
          \ let b:guesslang_new = v:option_new |
          \ let b:guesslang_old = v:option_old |
          \ silent doautocmd <nomodeline> User GuessLangUpdate
  endif
  autocmd BufWinEnter *
        \ if &l:spell && !exists('b:guesslang_explicit') |
        \   let b:guesslang_new = guesslang#guesslang() |
        \   let b:guesslang_old = &l:spelllang |
        \   let &l:spelllang    = b:guesslang_new |
        \   silent doautocmd <nomodeline> User GuessLangUpdate |
        \ endif |
        \ call s:augroupUpdateLang()
augroup end

function! s:augroupUpdateLang()
  augroup guesslangUpdateLang
    autocmd!
    autocmd CursorHold,CursorHoldI,InsertLeave <buffer> 
          \   if    (&l:spell && !exists('b:guesslang_explicit')) 
          \      && (b:changedtick >= 80  && wordcount().words >= 10) |
          \     exe 'silent doautocmd <nomodeline> GuessLang BufWinEnter' |
          \     exe 'autocmd! guesslangUpdateLang CursorHold,CursorHoldI,InsertLeave <buffer>' |
          \   endif
  augroup END
endfunction
