*GuessLang*
=========

This plug-in makes `Vim` autodetect the language of the text in a newly or
recently (after typing a couple of words) opened buffer (which is spell
checked, that is, `&spell` is set). It depends on the spell checker
`aspell` (contained in many Linux distributions by default).

The language is detected in-between those listed in the variable `g:guesslang_langs`. It is *empty* by default and has to be set by the user among those listed in `aspell dicts`! For example,
```vim
    let g:guesslang_langs = [ 'en_US', 'de_DE', 'es', 'it' ]
```

There is an autocommand event `User GuessLangUpdate`, that stores in the buffer-local variables `b:guesslang_old` and `b:guesslang_new` the previous and current value of `&l:spelllang`, the spell-check language.
In this way, a user command, for example for adding and removing abbreviations specific to a language, can hook in.
