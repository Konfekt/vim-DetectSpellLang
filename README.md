*DetectSpellLang*
=========

# Introduction

This `Vim` plug-in autodetects the spell-check language in which the text of  of a newly or recently (that is, after typing a couple of words) opened buffer is written.
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
It is *empty* by default and must be set by the user, choosing the appropriate spell-check languages among the output of the command `aspell dicts`!
For example,
```vim
    let g:guesslang_langs = [ 'en_US', 'de_DE', 'es', 'it' ]
```

# Credits

This plug-in fleshed out a [gist](https://gist.github.com/arenevier/1142114) by Arno Renevier that, later on, in May 2019, turns out to be part of a plug-in [GuessLang.vim](https://github.com/arenevier/vimguesslang/blob/master/GuessLang.vim) from 2011 by the same author.
