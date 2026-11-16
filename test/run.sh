#!/bin/sh
# Run the headless tests with each given editor (default: vim and nvim,
# whichever are installed), against aspell, hunspell (whichever are installed)
# and the stand-ins in test/bin. Exits non-zero if any run fails.
set -u
cd "$(dirname "$0")/.." || exit 1
[ $# -gt 0 ] || set -- vim nvim
LC_ALL=C LANG=C LANGUAGE= DSL_TEST_LOG=$(mktemp) || exit 1
export LC_ALL LANG LANGUAGE DSL_TEST_LOG
trap 'rm -f "$DSL_TEST_LOG"' EXIT
status=0

run() { # editor test program
  if [ "$(basename "$1")" = nvim ]; then
    DSL_PROGRAM=$3 "$1" --cmd 'let g:loaded_spellfile_plugin = 1' --headless --clean -i NONE -S "$2" </dev/null >/dev/null 2>&1
  else
    DSL_PROGRAM=$3 "$1" --cmd 'let g:loaded_spellfile_plugin = 1' -Nu NONE -i NONE -es -S "$2" </dev/null >/dev/null 2>&1
  fi || { status=1; grep -q "\\[$3\\]" "$DSL_TEST_LOG" || echo "FAIL $2 [$3]: editor exited early" >>"$DSL_TEST_LOG"; }
}

for editor in "$@"; do
  if ! command -v "$editor" >/dev/null 2>&1; then
    echo "skip: $editor not found"
    continue
  fi
  echo "== $editor"
  : >"$DSL_TEST_LOG"
  run "$editor" test/test_setup.vim none
  for program in "$PWD/test/bin/aspell" "$PWD/test/bin/hunspell"; do
    run "$editor" test/test_setup.vim "$program"
  done
  for program in aspell hunspell; do
    if command -v "$program" >/dev/null 2>&1; then
      run "$editor" test/test_setup.vim "$program"
      run "$editor" test/test_detect.vim "$program"
    else
      echo "skip: $program not found" >>"$DSL_TEST_LOG"
    fi
  done
  cat "$DSL_TEST_LOG"
done
exit "$status"
