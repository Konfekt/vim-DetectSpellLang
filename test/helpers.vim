" Shared set-up for the tests: puts the plug-in on 'runtimepath' and records
" failed assertions in the log file $DSL_TEST_LOG.
set nomore hidden
let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let &runtimepath = s:root . ',' . &runtimepath

function! TestRoot() abort
  return s:root
endfunction

function! LoadPlugin() abort
  runtime plugin/detectspelllang.vim
endfunction

function! WriteText(name, lines) abort
  let file = tempname() . '-' . a:name
  call writefile(a:lines, file)
  return file
endfunction

" Runs every function whose name starts with Test_ and quits, with a non-zero
" exit code if any assertion failed.
function! RunTests(name) abort
  let v:errors = []
  let tests = sort(map(split(execute('function /^Test_'), "\n"),
        \ {key, val -> matchstr(val, '\<Test_\w\+')}))
  for test in tests
    try
      call call(test, [])
    catch
      call add(v:errors, test . ': ' . v:exception . ' @ ' . v:throwpoint)
    endtry
  endfor
  if empty(tests)
    call add(v:errors, 'no tests ran')
  endif
  let header = a:name . ' [' . $DSL_PROGRAM . ']'
  call writefile(empty(v:errors)
        \ ? ['ok   ' . header . ': ' . join(tests)]
        \ : ['FAIL ' . header] + map(copy(v:errors), '"  " . v:val'),
        \ $DSL_TEST_LOG, 'a')
  if empty(v:errors)
    qall!
  endif
  cquit!
endfunction
