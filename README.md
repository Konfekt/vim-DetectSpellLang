*DetectSpellLang*
=========

# Introduction

This plug-in makes Vim autodetect the tongue (= `&spelllang`) of the text contained in a buffer (which is spell checked, that is, `&spell` is set).
It depends on the spell checker `aspell` (which is contained in many Linux distributions by default, in Mac OS, and also available for Microsoft Windows, where the path to its executable must be added to the `%PATH%` environment variable).

# Setup

This plug-in only acts on buffers that are spell checked, that is, `&l:spell` is set.
To ensure that certain file types, such as `text`, `markdown` and `mail`,
are spell checked, add either the line

```vim
  autocmd FileType text,markdown,mail setlocal spell
```

or the line

```vim
  setlocal spell
```

to `text.vim`, `markdown.vim` and `mail.vim` in `~/.vim/ftplugin` (on Microsoft Windows, in `%USERPROFILE%\vimfiles\ftplugin`).

The spell-check language is detected in-between those listed in the variable `g:guesslang_langs`.
It is *empty* by default and must be set by the user, choosing the appropriate spell-check languages among those listed in the output of the command `aspell dicts`!
For example,

```vim
    let g:guesslang_langs = [ 'en_US', 'de_DE', 'es', 'it' ]
```

# Configuration

- The value of `g:guesslang_lines` defines how many lines are tested for spelling mistakes by `aspell` to derive the suitable spellcheck-language.
    By default

    ```vim
    let g:guesslang_lines = 100
    ```

- The values in the dictionary 'g:guesslang_ftoptions' define filetype- dependent options for `aspell` (to specify the filter mode, for example).
    By default

    ```vim
    let g:guesslang_ftoptions = {
        \ 'tex'   : [ '--mode=tex', '--dont-tex-check-comments' ],
        \ 'html'  : '--mode=html',
        \ 'nroff' : '--mode=nroff',
        \ 'perl'  : '--mode=perl',
        \ 'c'     : '--mode=ccpp',
        \ 'cpp'   : '--mode=ccpp',
        \ 'sgml'  : '--mode=sgml',
        \ 'xml'   : '--mode=sgml',
        \}
    ```

- The value of `g:guesslang_threshold` defines the percentage of spelling mistakes among all words below which a spellcheck-language is recognized as correct.
    For example, with the default

    ```vim
    let g:guesslang_threshold' = 20
    ```

  and g:guesslang_langs = [ 'en_US', 'de_DE' ], if less than 20% of all words in the buffer are spelling mistakes for `'en_US'`, then `'DetectSpellLang'` does not verify if the percentage of spelling mistakes for `'de_DE'` is below that for `'en_US'`.

- The autocommand event

    ```vim
    User GuessLangUpdate
    ```

  provides by the buffer-local variables `b:guesslang_old` and `b:guesslang_new` the previous and current value of `&l:spelllang`, the spell-check language.
    This way, a user command, for example for adding and removing abbreviations specific to a language, can hook in.

# Credits

This plug-in fleshes out a [gist](https://gist.github.com/arenevier/1142114) by Arno Renevier that, later on, in May 2019, turns out to be part of a plug-in [GuessLang.vim](https://github.com/arenevier/vimguesslang/blob/master/GuessLang.vim) from 2011 by the same author.
