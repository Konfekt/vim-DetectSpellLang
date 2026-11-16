" Set-up of the plug-in: the dictionary list and failing gracefully.
" Run with the C locale, as test/run.sh does, and with $DSL_PROGRAM naming
" aspell, hunspell or a stand-in in test/bin.
execute 'source' fnameescape(expand('<sfile>:p:h') . '/helpers.vim')

if $DSL_PROGRAM ==# 'none'
  " the user's 'cpoptions' must survive an aborted set-up
  let g:detectspelllang_program = '/nonexistent/aspell'
  let s:cpo = &cpoptions . 'J'
  let &cpoptions = s:cpo
  try
    call LoadPlugin()
  catch /DetectSpellLang: Please install/
    let s:caught = 1
  endtry

  function! Test_missing_program_is_reported() abort
    call assert_true(exists('s:caught'), 'missing spell checker not reported')
  endfunction

  function! Test_missing_program_keeps_cpoptions() abort
    call assert_equal(s:cpo, &cpoptions)
  endfunction
else
  let g:detectspelllang_program = $DSL_PROGRAM
  call LoadPlugin()
  let s:checker = $DSL_PROGRAM =~? 'aspell' ? 'aspell' : 'hunspell'

  function! Test_dictionaries_are_clean() abort
    let langs = g:detectspelllang_langs[s:checker]
    call assert_true(len(langs) >= 2, 'too few dictionaries: ' . string(langs))
    call assert_equal([], filter(copy(langs), 'v:val !~# ''^\a\+\%(_\a\+\)\=$'''),
          \ 'malformed dictionary names')
    call assert_equal(len(langs), len(uniq(sort(copy(langs)))), 'duplicates in ' . string(langs))
  endfunction

  " the C locale has no language, so English has to come first
  function! Test_english_first_without_system_language() abort
    call assert_equal('', matchstr(v:lang, '^\a\a\ze\%([_.@-]\|$\)'), 'test needs the C locale')
    call assert_match('^en', g:detectspelllang_langs[s:checker][0], string(g:detectspelllang_langs))
  endfunction

  if $DSL_PROGRAM =~# '[\/]test[\/]bin[\/]'
    function! Test_stand_in_dictionaries() abort
      call assert_equal(s:checker ==# 'aspell' ? ['en', 'en_US', 'de_DE'] : ['en_US', 'de_DE'],
            \ g:detectspelllang_langs[s:checker])
    endfunction
  endif
endif

call RunTests('test_setup.vim')
