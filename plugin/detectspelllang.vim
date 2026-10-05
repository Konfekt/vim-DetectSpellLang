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

" the kind of spell checker, whatever path g:detectspelllang_program holds
let s:checker = g:detectspelllang_program =~? '\<aspell\>' ? 'aspell' :
      \         g:detectspelllang_program =~? '\<hunspell\>' ? 'hunspell' : ''

if !exists('g:detectspelllang_langs')
  let g:detectspelllang_langs = {}
  if s:checker ==# 'aspell'
    let dicts = systemlist(shellescape(g:detectspelllang_program) . ' dicts')
    let dicts = uniq(map(dicts, {key, val -> substitute(val, '-[^\n]*', '', '')}))
  elseif s:checker ==# 'hunspell'
    " hunspell -D lists the dictionaries on stderr
    let output = system((has('win32') && &shell =~? '\<cmd\>' ? "set LANG=en && " : "LC_ALL=C ") . shellescape(g:detectspelllang_program) . " -D 2>&1")
    " keep only the dictionary paths and reduce them to the dictionary names
    let dicts = uniq(sort(map(
          \ filter(split(output, '\n'), {key, val -> val =~# '^\%([A-Za-z]:[\\/]\|/\)'}),
          \ {key, val -> substitute(val, '^.*[\\/]\|\.\%(aff\|dic\)$', '', 'g')})))
    unlet output
  else
    let dicts = []
  endif

  " try the system language and English first: likelier and faster matches
  let system_lang = tolower(matchstr(v:lang, '^\a\a'))
  let g:detectspelllang_langs[s:checker] =
        \ filter(copy(dicts), 'v:val =~# "^" . system_lang') +
        \ filter(copy(dicts), 'v:val !~# "^" . system_lang && v:val =~# "^en"') +
        \ filter(dicts,       'v:val !~# "^" . system_lang && v:val !~# "^en"')
  unlet system_lang dicts

  if len(g:detectspelllang_langs[s:checker]) < 2
    let s:errmsg =
          \ 'DetectSpellLang: Could not autodetect more than one language for ' . g:detectspelllang_program . '. ' .
          \ 'Please list at least two different languages in g:detectspelllang_langs.' . s:checker . '! '
    if tolower(matchstr(v:lang, '^\a\a')) !~? '^en'
      let s:errmsg .= 'Check if the ' . v:lang . ' dictionary is installed; '
    endif
    let s:errmsg .= 'Use ' . (s:checker ==# 'aspell' ? 'aspell dicts' : 'hunspell -D') . ' to list available dictionaries!'
    echoerr s:errmsg
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

" number of words above which a buffer's sample is considered large enough
" that scheduling another detection attempt is not worth its cost
let s:min_words_for_sample = 10

function! s:augroupUpdateLang()
  augroup DetectSpellLangUpdateLang
    " clear only this buffer's autocmds: a bare 'autocmd!' would also wipe
    " the pending retry hook of every other armed buffer
    autocmd! * <buffer>
    autocmd CursorHold,CursorHoldI,BufWrite <buffer>
          \   if    (&l:spell && !exists('b:detectspelllang_explicit'))
          \      && (wordcount().words >= s:min_words_for_sample) |
          \     call detectspelllang#apply() |
          \     exe 'autocmd! DetectSpellLangUpdateLang * <buffer>' |
          \   endif
  augroup END
endfunction

" detect the language, then arm a one-shot retry for when the buffer did not
" yet hold enough text for a reliable sample, or disarm a stale one
function! s:detectAndArm() abort
  call detectspelllang#apply()
  if wordcount().words < s:min_words_for_sample
    call s:augroupUpdateLang()
  elseif exists('#DetectSpellLangUpdateLang')
    autocmd! DetectSpellLangUpdateLang * <buffer>
  endif
endfunction

augroup DetectSpellLang
  autocmd!
  if exists('##OptionSet')
    " b:detectspelllang_lock is set while the plugin itself assigns &l:spelllang
    autocmd OptionSet spelllang
          \ if !exists('b:detectspelllang_lock') |
          \   let b:detectspelllang_explicit = 1 |
          \   let b:detectspelllang_new = v:option_new |
          \   let b:detectspelllang_old = v:option_old |
          \   silent doautocmd <nomodeline> User DetectSpellLangUpdate |
          \ endif
    autocmd OptionSet spell
          \ if exists('b:detectspelllang_modelines_read') && !exists('b:detectspelllang_explicit') && v:option_new |
          \   call s:detectAndArm() |
          \ endif
  endif
  autocmd BufWinEnter *
        \ let b:detectspelllang_modelines_read = 1 |
        \ if &l:spell && !exists('b:detectspelllang_explicit') |
        \   call s:detectAndArm() |
        \ endif
augroup end
if argc() > 1
  silent doautocmd DetectSpellLang BufWinEnter
endif

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
