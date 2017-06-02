" From https://gist.github.com/arenevier/1142114

function! guesslang#guesslang() abort
  " Check Middle
  let end = line('$')
  let middle = (1+end)/2
  let guesslines = min([g:guesslang_lines,end])/2
  let start = middle - guesslines
  let end = middle + guesslines
  let content = join( getline( start, end ), ' ' )
  if empty(content) || len(g:guesslang_langs) < 2
    " default to first (=system) language
    let lang = g:guesslang_langs[0]
  else
    let words = len(split(content))

    if     &l:filetype is# 'mail'         | let mode = ''
    elseif &l:filetype is# 'tex'          | let mode = ' --mode=tex --dont-tex-check-comments'
    elseif &l:filetype is# 'html'         | let mode = ' --mode=html'
    elseif &l:filetype is# 'nroff'        | let mode = ' --mode=nroff'
    elseif &l:filetype is# 'perl'         | let mode = ' --mode=perl'
    elseif &l:filetype =~# '\v^c(pp)?$'   | let mode = ' --mode=ccpp'
    elseif &l:filetype =~# '\v^(sg|x)ml$' | let mode = ' --mode=sgml'
    else                                  | let mode = ''
    endif

    " For each language, get number of misspelled words according to aspell.
    " The language with the least misspelled words is the spell language
    for guess in g:guesslang_langs
      let mist = len(split(system('aspell --lang=' . guess . mode . ' list ', content)))
      " already correct lang if less threshold many % wrong
      if (mist * 100 / words) < g:guesslang_threshold
        let lang = guess
        break
      elseif !exists('mistmin') || mist < mistmin
        let mistmin = mist
        let lang = guess
      endif
    endfor
  endif

  let lang_pattern = '^\a\a'
  let lang = tolower(matchstr(lang, lang_pattern))
  return lang
endfunction

