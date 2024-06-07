*DetectSpellLang*
=========

# Introduction

This Vim plug-in autodetects the tongue (= `&spelllang`) of the text in a buffer (if it is spell checked, that is, `&spell` is set, and `&spelllang` has not been explicitly set, say by a modeline `:help modeline`).

# Installation

It uses either the spell checker `aspell` or `hunspell` (which are installed in many Linux distributions, in Mac OS, and [both](http://aspell.net/man-html/WIN32-Notes.html) [available](https://chocolatey.org/packages/hunspell.portable) for Microsoft Windows.

In Microsoft Windows the path to the executable must

- be either added to the `%PATH%` environment variable (say by [Rapidee](http://www.rapidee.com/)), or
- set by `g:detectspelllang_program`, say

```vim
    let g:detectspelllang_program = 'C:\Program Files (x86)\Aspell\bin\aspell.exe'
```

The Scoop package [aspell](https://github.com/ScoopInstaller/Main/blob/master/bucket/aspell.json) or the Chocolatey package [hunspell](https://chocolatey.org/packages/hunspell.portable) automatically add these to the `%PATH`.

# Set-up

This plug-in only operates in buffers that are spell checked, that is, `&l:spell` is set.
To ensure that certain file types, such as `text`, `markdown` and `mail`, are spell checked, add either the line

```vim
    autocmd FileType text,markdown,mail setlocal spell
```

or the line

```vim
    setlocal spell
```

to `text.vim`, `markdown.vim` and `mail.vim` in `~/.vim/ftplugin` (on Microsoft Windows, in `%USERPROFILE%\vimfiles\ftplugin`).

The executable of the spell checker is automatically detected and preference given to `aspell`.
You can override this automatic detection by adding to you `vimrc` say

```vim
    let g:detectspelllang_program = 'hunspell'
```

The language is detected, depending on whether `aspell` respectively `hunspell`
is used, among those listed in `g:detectspelllang_langs.aspell` respectively
`g:detectspelllang_langs.hunspell`. It is *empty* by default and has to be
set by the user to a list of languages included in that of the output of the
command `aspell dicts` respectively `hunspell -D`**!**
For example,

```vim
    let g:detectspelllang_langs = {
      \ 'aspell'   : [ 'en_US', 'de_DE', 'es', 'it' ],
      \ 'hunspell' : [ 'en_US', 'de_DE', 'es_ES', 'it_IT' ],
      \ }
```

Please pay attention, as `hunspell` does, to the upper case of the suffix of the language code.

# Configuration

- The value of `g:detectspelllang_lines` defines how many lines are tested for spelling mistakes by `aspell` or `hunspell` to derive the suitable spellcheck-language.
    By default

    ```vim
    let g:detectspelllang_lines = 1000
    ```

- The values in the dictionary 'g:detectspelllang_ftoptions' define filetype dependent options for `aspell` or `hunspell` (to specify the filter mode, for example).
    By default

    ```vim
    let g:detectspelllang_ftoptions = {
    \ 'aspell' : {
        \ 'tex'   : ['--mode=tex', '--dont-tex-check-comments'],
        \ 'html'  : ['--mode=html'],
        \ 'nroff' : ['--mode=nroff'],
        \ 'perl'  : ['--mode=perl'],
        \ 'c'     : ['--mode=ccpp'],
        \ 'cpp'   : ['--mode=ccpp'],
        \ 'sgml'  : ['--mode=sgml'],
        \ 'xml'   : ['--mode=sgml'],
        \},
    \ 'hunspell' : {
        \ 'tex'   : ['-t'],
        \ 'html'  : ['-H'],
        \ 'nroff' : ['-n'],
        \ 'odt'   : ['-O'],
        \ 'xml'   : ['-X'],
        \}
    \ }
    ```

- The value of `g:detectspelllang_threshold` defines the percentage of spelling mistakes among all words below which a spellcheck-language is recognized as correct.
    For example, with the default

    ```vim
    let g:detectspelllang_threshold = 20
    ```

    and g:detectspelllang_langs = [ 'en_US', 'de_DE' ], if less than 20% of all words in the buffer are spelling mistakes for `'en_US'`, then `'DetectSpellLang'` does not verify if the percentage of spelling mistakes for `'de_DE'` is below that for `'en_US'`.

- The autocommand event

    ```vim
    User DetectSpellLangUpdate
    ```

    provides by the buffer-local variables `b:detectspelllang_old` and `b:detectspelllang_new` the previous and current value of `&l:spelllang`, the spell-check language.
    This way, a user command, for example for adding and removing abbreviations specific to a language, can hook in.

# Credits

This plug-in fleshes out a [gist](https://gist.github.com/arenevier/1142114) by Arno Renevier that, later on, in May 2019, turns out to be part of a plug-in [GuessLang.vim](https://github.com/arenevier/vimguesslang/blob/master/GuessLang.vim) from 2011 by the same author.
