if exists('g:loaded_DetectSpellLang') || &compatible
  finish
endif
let g:loaded_DetectSpellLang = 1

let s:keepcpo = &cpoptions
set cpoptions&vim
" ------------------------------------------------------------------------------

" Lists the dictionaries that the spell checker of kind {checker} reports, with
" the system language and English first, as they are likelier and faster matches.
function! s:dictionaries(checker) abort
  let program = shellescape(g:detectspelllang_program)
  if a:checker ==# 'aspell'
    " strip variants such as en_GB-ize or de-neu
    let dicts = map(split(system(program . ' dicts'), '\r\=\n'),
          \ {key, val -> substitute(val, '-.*', '', '')})
  else
    " hunspell -D lists the dictionaries on stderr; keep only their paths and
    " reduce them to the dictionary names
    let output = system((has('win32') && &shell =~? '\<cmd\>' ? 'set LANG=en && ' : 'LC_ALL=C ') . program . ' -D 2>&1')
    let dicts = map(
          \ filter(split(output, '\r\=\n'), {key, val -> val =~# '^\%([A-Za-z]:[\\/]\|/\)'}),
          \ {key, val -> substitute(val, '^.*[\\/]\|\.\%(aff\|dic\)$', '', 'g')})
  endif
  let dicts = uniq(sort(filter(dicts, {key, val -> !empty(val)})))

  " v:lang is, for example, C or POSIX if no locale is set
  let system_lang = tolower(matchstr(v:lang, '^\a\a\ze\%([_.@-]\|$\)'))
  let first = empty(system_lang) ? [] : filter(copy(dicts), {key, val -> val =~# '^' . system_lang})
  call filter(dicts, {key, val -> index(first, val) < 0})
  return first + filter(copy(dicts), {key, val -> val =~# '^en'}) + filter(dicts, {key, val -> val !~# '^en'})
endfunction

" Sets up g:detectspelllang_program and g:detectspelllang_langs, unless set
" by the user, and returns an error message if that fails.
function! s:setup() abort
  if !exists('g:detectspelllang_program')
    let g:detectspelllang_program =
          \ executable('aspell')   ? 'aspell'   :
          \ executable('hunspell') ? 'hunspell' : ''
  endif
  if !executable(g:detectspelllang_program)
    return 'DetectSpellLang: Please install aspell or hunspell!'
  endif

  if exists('g:detectspelllang_langs')
    return ''
  endif
  let checker = detectspelllang#checker()
  let g:detectspelllang_langs = {checker : s:dictionaries(checker)}
  if len(g:detectspelllang_langs[checker]) >= 2
    return ''
  endif

  let msg =
        \ 'DetectSpellLang: Could not autodetect more than one language for ' . g:detectspelllang_program . '. ' .
        \ 'Please list at least two different languages in g:detectspelllang_langs.' . checker . '! '
  if v:lang !~? '^en'
    let msg .= 'Check if the ' . v:lang . ' dictionary is installed; '
  endif
  return msg . 'Use ' . (checker ==# 'aspell' ? 'aspell dicts' : 'hunspell -D') . ' to list available dictionaries!'
endfunction

let s:errmsg = s:setup()
if !empty(s:errmsg)
  let &cpoptions = s:keepcpo
  unlet s:keepcpo
  echoerr s:errmsg
  finish
endif
unlet s:errmsg

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
    " TextChanged/TextChangedI fire as soon as an edit (e.g. a paste)
    " settles, so they usually catch it well before CursorHold(I) would
    " (which waits out 'updatetime' of inactivity); TextChanged is
    " documented to not trigger while there is pending typeahead, so
    " CursorHold(I) is kept as a guaranteed fallback, and BufWrite as a
    " fallback for non-interactive edits
    autocmd TextChanged,TextChangedI,CursorHold,CursorHoldI,BufWrite <buffer>
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
  " covers &l:spell being turned on indirectly, e.g. by an ftplugin, when
  " the filetype is assigned after the buffer was already displayed (a
  " dynamic content-based filetype detector is a common source of this);
  " OptionSet spell does not reliably fire in that case because Vim does
  " not nest autocommands triggered by other, non-'++nested' autocommands
  autocmd FileType *
        \ if exists('b:detectspelllang_modelines_read') && !exists('b:detectspelllang_explicit') && &l:spell |
        \   call s:detectAndArm() |
        \ endif
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
let &cpoptions = s:keepcpo
unlet s:keepcpo
