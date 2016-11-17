if !executable('aspell')
  echoerr 'GuessLang: Please install ASPELL!'
  finish
endif

if !exists('g:guesslang_langs')

  if tolower(matchstr(v:lang, '^\a\a')) is# 'en'
    echoerr 'GuessLang: Please list at least two different languages in g:guesslang_langs!'
    finish
  endif

  let v_lang = matchstr(v:lang, '^\a\a_\a\a')
  let dicts = systemlist('aspell dicts')
  let g:guesslang_langs = filter(dicts, 'v:val is# "'. 'en' . '"' . '||' . 'v:val is# "' . v_lang . '"')
  if len(g:guesslang_langs) < 2
    echoerr 'GuessLang: Please list at least two different languages in g:guesslang_langs!'
    finish
  endif

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
