function! detectspelllang#detectspelllang() abort
  let checker = g:detectspelllang_program =~? '\<aspell\>' ? 'aspell' : 'hunspell'
  let langs = get(g:detectspelllang_langs, checker, [])
  if empty(langs)
    return ''
  endif

  " take lines around middle
  let last = line('$')
  let middle = (1 + last)/2
  let number_of_lines = min([g:detectspelllang_lines, last])/2
  let lines = getline(middle - number_of_lines, middle + number_of_lines)

  let opts = []
  if exists('g:detectspelllang_ftoptions.' . checker)
    let ftoptions = g:detectspelllang_ftoptions[checker]
    for filetype in keys(ftoptions)
      if &l:filetype is# filetype
        let opts = get(ftoptions, filetype, [])
        break
      endif
    endfor
  endif

  " filter out whatever appears not to be prose
  if empty(opts)
    let lines = filter(lines, 'v:val =~# "\\v(^|[[:space:]])[[:lower:][:upper:]]{2,}[[:space:]][[:lower:][:upper:]]"')
  endif

  " default to first (=system) language
  let lang = langs[0]

  if !empty(lines) && len(langs) >= 2
    let last = len(lines)
    let middle = (1 + last)/2
    let lines = lines[max([0, middle - g:detectspelllang_lines]):min([last, middle + g:detectspelllang_lines])]

    let words = len(split(join(lines, ' ')))

    " For each language, get number of misspelled words according to aspell or hunspell.
    " The language with the least misspelled words is the spell language.
    if words > 0
      let lang = ''
      let program = shellescape(g:detectspelllang_program)
      for guess in langs
        let output = system(
              \ checker ==# 'aspell' ?
              \ program . ' --lang=' . shellescape(guess) . ' ' . join(opts) . ' list' :
              \ program . ' -d ' . shellescape(guess) . ' ' . join(opts) . ' -l -' ,
              \ lines)
        " a failing dictionary must not win with zero misspellings
        if v:shell_error
          continue
        endif
        let mist = len(split(output))
        " already correct lang if less threshold many % wrong
        if (mist * 100 / words) < g:detectspelllang_threshold
          let lang = guess
          break
        elseif empty(lang) || mist < mistmin
          let mistmin = mist
          let lang = guess
        endif
      endfor
      " all checks failed; keep the default language
      if empty(lang)
        let lang = langs[0]
      endif
    endif
  endif

  return tolower(matchstr(lang, '^\a\a\(_\a\a\)\?'))
endfunction

" Detect the spell language and assign it to &l:spelllang, guarding the
" OptionSet autocmd against the plugin's own assignment.
function! detectspelllang#apply() abort
  let new = detectspelllang#detectspelllang()
  if empty(new)
    return
  endif
  let b:detectspelllang_old = &l:spelllang
  let b:detectspelllang_new = new
  let b:detectspelllang_lock = 1
  try
    silent let &l:spelllang = new
  finally
    unlet b:detectspelllang_lock
  endtry
  silent doautocmd <nomodeline> User DetectSpellLangUpdate
endfunction
