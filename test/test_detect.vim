scriptencoding utf-8
" Detection in buffers with a real aspell or hunspell that has English and
" German dictionaries, as named by $DSL_PROGRAM.
execute 'source' fnameescape(expand('<sfile>:p:h') . '/helpers.vim')

let s:english = ['The quick brown fox jumps over the lazy dog while the farmer',
      \ 'watches from the window of his house and drinks a cup of coffee.']
let s:german = ['Der schnelle braune Fuchs springt über den faulen Hund, während',
      \ 'der Bauer vom Fenster seines Hauses zuschaut und Kaffee trinkt.']

let g:detectspelllang_program = $DSL_PROGRAM
call LoadPlugin()

function! s:edit(name, lines) abort
  execute 'edit' fnameescape(WriteText(a:name, a:lines))
endfunction

function! Test_detects_english_and_german() abort
  call s:edit('en.txt', s:english)
  call assert_match('^en', &l:spelllang)
  call s:edit('de.txt', s:german)
  call assert_match('^de', &l:spelllang)
endfunction

function! Test_user_event_reports_old_and_new_language() abort
  let g:events = []
  augroup DetectSpellLangTest
    autocmd!
    autocmd User DetectSpellLangUpdate
          \ call add(g:events, [b:detectspelllang_old, b:detectspelllang_new])
  augroup END
  call s:edit('event.txt', s:german)
  autocmd! DetectSpellLangTest
  call assert_equal(1, len(g:events))
  call assert_match('^de', g:events[-1][1])
endfunction

function! Test_explicit_spelllang_is_kept() abort
  call s:edit('explicit.txt', s:german)
  setlocal spelllang=fr
  call assert_true(exists('b:detectspelllang_explicit'))
  doautocmd <nomodeline> BufWinEnter
  call assert_equal('fr', &l:spelllang)
endfunction

function! Test_short_buffer_is_detected_once_it_grows() abort
  call s:edit('short.txt', ['Hallo'])
  call assert_true(exists('#DetectSpellLangUpdateLang#TextChanged#<buffer>'), 'retry not armed')
  call setline(1, s:german)
  doautocmd <nomodeline> TextChanged
  call assert_match('^de', &l:spelllang)
  call assert_false(exists('#DetectSpellLangUpdateLang#TextChanged#<buffer>'), 'retry not disarmed')
endfunction

function! Test_spell_set_by_filetype_triggers_detection() abort
  set nospell
  call s:edit('ft.txt', s:german)
  call assert_false(&l:spell)
  augroup DetectSpellLangTest
    autocmd!
    autocmd FileType text setlocal spell
  augroup END
  setfiletype text
  autocmd! DetectSpellLangTest
  set spell
  call assert_match('^de', &l:spelllang)
endfunction

function! Test_filetype_options_are_passed() abort
  " LaTeX commands would count as English words without the TeX filter
  call s:edit('de.tex', ['\documentclass{article}\usepackage{babel}\begin{document}'] + s:german + ['\end{document}'])
  setlocal filetype=tex spelllang=en
  unlet! b:detectspelllang_explicit
  call detectspelllang#apply()
  call assert_match('^de', &l:spelllang)
endfunction

function! s:run() abort
  set spell
  call RunTests('test_detect.vim')
endfunction

if v:vim_did_enter
  call s:run()
else
  augroup DetectSpellLangTestRun
    autocmd VimEnter * ++nested call s:run()
  augroup END
endif
