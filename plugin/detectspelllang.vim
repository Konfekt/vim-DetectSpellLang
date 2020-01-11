if exists('g:loaded_DetectSpellLang') || &cp
  finish
endif
let g:loaded_DetectSpellLang = 1

let s:keepcpo         = &cpo
set cpo&vim
" ------------------------------------------------------------------------------

if !exists('g:detectspelllang_program')
  if executable('aspell')
    let g:detectspelllang_program = 'aspell'
  elseif executable('hunspell')
    let g:detectspelllang_program = 'hunspell'
  else
    let g:detectspelllang_program = ''
  endif
endif

if !executable(g:detectspelllang_program)
  echoerr 'DetectSpellLang: Please install aspell or hunspell!'
  finish
endif

let g:detectspelllang_aspell = (g:detectspelllang_program =~? '\<aspell\>') 

if !exists('g:detectspelllang_langs')
  if tolower(matchstr(v:lang, '^\a\a')) is# 'en'
    echoerr 'DetectSpellLang: Please list at least two different languages in g:detectspelllang_langs.' . g:detectspelllang_program . '!'
    finish
  endif

  echomsg 'DetectSpellLang: Guessing second tongue other than English installed...'
  let g:detectspelllang_langs = {}

  let v_lang = matchstr(v:lang, '^\a\a_\a\a')
  let dicts = systemlist(g:detectspelllang_aspell ? 'aspell dicts' : 'hunspell -D')
  let s:langs = filter(dicts, 'v:val is# "'. 'en' . '"' . '||' . 'v:val is# "' . v_lang . '"')
  exe 'let g:detectspelllang_langs.g:detectspelllang_program = ' . 's:langs'
  unlet s:langs
  if len(g:detectspelllang_langs.g:detectspelllang_program) < 2
    echoerr 'DetectSpellLang: Please list at least two different languages in g:detectspelllang_langs.' . g:detectspelllang_program . '!'
    finish
  endif
endif

if !exists('g:detectspelllang_lines')     | let g:detectspelllang_lines = 1000   | endif
if !exists('g:detectspelllang_threshold') | let g:detectspelllang_threshold = 20 | endif
if !exists('g:detectspelllang_ftoptions')
  let g:detectspelllang_ftoptions = {}
endif
if !exists('g:detectspelllang_ftoptions.aspell')
  let g:detectspelllang_ftoptions.aspell = {
    \ 'tex'   : ['--mode=tex', '--dont-tex-check-comments'],
    \ 'html'  : ['--mode=html'],
    \ 'nroff' : ['--mode=nroff'],
    \ 'perl'  : ['--mode=perl'],
    \ 'c'     : ['--mode=ccpp'],
    \ 'cpp'   : ['--mode=ccpp'],
    \ 'sgml'  : ['--mode=sgml'],
    \ 'xml'   : ['--mode=sgml'],
    \}
endif
if !exists('g:detectspelllang_ftoptions.hunspell')
  let g:detectspelllang_ftoptions.hunspell = {
    \ 'tex'   : ['-t'],
    \ 'html'  : ['-H'],
    \ 'nroff' : ['-n'],
    \ 'odt'   : ['-O'],
    \ 'xml'   : ['-X'],
    \}
endif

function! s:augroupUpdateLang()
  augroup DetectSpellLangUpdateLang
    autocmd!
    autocmd CursorHold,CursorHoldI,BufWrite <buffer>
          \   if    (&l:spell && !exists('b:detectspelllang_explicit'))
          \      && (b:changedtick >= 80  && wordcount().words >= 10) |
          \     exe 'silent doautocmd <nomodeline> DetectSpellLang BufWinEnter' |
          \     exe 'autocmd! DetectSpellLangUpdateLang CursorHold,CursorHoldI,BufWrite <buffer>' |
          \   endif
  augroup END
endfunction

augroup DetectSpellLang
  autocmd!
  if exists('##OptionSet')
    autocmd OptionSet spelllang
          \ let b:detectspelllang_explicit = 1 |
          \ let b:detectspelllang_new = v:option_new |
          \ let b:detectspelllang_old = v:option_old |
          \ silent doautocmd <nomodeline> User DetectSpellLangUpdate
    autocmd OptionSet spell
          \ if v:option_new && !exists('b:detectspelllang_explicit') |
          \   let b:detectspelllang_new = detectspelllang#detectspelllang() |
          \   let b:detectspelllang_old = &l:spelllang |
          \   silent let &l:spelllang    = b:detectspelllang_new |
          \   silent doautocmd <nomodeline> User DetectSpellLangUpdate |
          \ endif
  endif
  autocmd BufWinEnter *
        \ if &l:spell && !exists('b:detectspelllang_explicit') |
        \   let b:detectspelllang_new = detectspelllang#detectspelllang() |
        \   let b:detectspelllang_old = &l:spelllang |
        \   silent let &l:spelllang    = b:detectspelllang_new |
        \   silent doautocmd <nomodeline> User DetectSpellLangUpdate |
        \ endif |
        \ call s:augroupUpdateLang()
augroup end
if argc() > 1
  silent doautocmd DetectSpellLang BufWinEnter
endif

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
