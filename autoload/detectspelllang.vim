function! detectspelllang#detectspelllang() abort
  " take lines around middle
  let end = line('$')
  let middle = (1 + end)/2
  let number_of_lines = min([g:detectspelllang_lines, end])/2
  let lines = getline( middle - number_of_lines, middle + number_of_lines )

  let opts = []
  if exists('g:detectspelllang_ftoptions.' . g:detectspelllang_program)
    let ftoptions = g:detectspelllang_ftoptions[g:detectspelllang_program]
    for filetype in keys(ftoptions)
      if &l:filetype is# filetype
        let opts = get(ftoptions, filetype, '')
        break
      endif
    endfor
  endif

  " filter out whatever appears not to be prose
  if empty(opts)
    let lines = filter(lines, 'v:val =~# "\\v(^|[[:space:]])[[:lower:][:upper:]]{2,}[[:space:]][[:lower:][:upper:]]"')
  endif

  let langs = g:detectspelllang_langs[g:detectspelllang_program]
  if empty(lines) || len(langs) < 2
    " default to first (=system) language
    let lang = langs[0]
  else
    let end = len(lines)
    let middle = (1 + end)/2
    let lines = lines[max([0, middle - g:detectspelllang_lines]):min([end, middle + g:detectspelllang_lines])]

    let words = len(split(join(lines, ' ')))

    " For each language, get number of misspelled words according to aspell or hunspell.
    " The language with the least misspelled words is the spell language.
    for guess in langs
      silent let mist = len(split(system(
            \ g:detectspelllang_aspell ?
            \ 'aspell --lang=' . guess . ' ' . join(opts) . ' list' :
            \ 'hunspell -d ' . guess . ' ' . join(opts) . ' -l -' ,
            \ lines)))
      " already correct lang if less threshold many % wrong
      if (mist * 100 / words) < g:detectspelllang_threshold
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

