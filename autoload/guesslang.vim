" From https://gist.github.com/arenevier/1142114

function! guesslang#guesslang() abort
  " Check Middle
  let end = line('$')
  let middle = (1 + end)/2
  " Give some leeway before filtering out whatever appears not to be prose
  let guesslines = min([g:guesslang_lines * 10, end])/2
  let lines = getline( middle - guesslines, middle + guesslines )
  let content = filter(lines, 'v:val =~# "\\v(^|[[:space:]])[[:lower:][:upper:]]{2,}[[:space:]][[:lower:][:upper:]]"')

  if empty(content) || len(g:guesslang_langs) < 2
    " default to first (=system) language
    let lang = g:guesslang_langs[0]
  else
    let end = len(content)
    let middle = (1 + end)/2
    let content = content[max([0, middle - g:guesslang_lines]):min([end, middle + g:guesslang_lines])]

    let words = len(split(join(content, ' ')))

    let opts = []
    if exists('g:guesslang_ftoptions')
      for filetype in keys(g:guesslang_ftoptions)
        if &l:filetype is# filetype
          let opts = get(g:guesslang_ftoptions, filetype, '')
          break
        endif
      endfor
    endif

    " For each language, get number of misspelled words according to aspell.
    " The language with the least misspelled words is the spell language
    for guess in g:guesslang_langs
      silent let mist = len(split(system('aspell --lang=' . guess . ' ' . join(opts) . ' list', content)))
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

  let lang_pattern = '^\a\a\(_\a\a\)\?'
  let lang = tolower(matchstr(lang, lang_pattern))
  return lang
endfunction

