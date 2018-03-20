if exists("g:loaded_mline") || &cp
  finish
endif
let g:loaded_mline = 1

if v:vim_did_enter
  call mline#init()
else
  augroup Mline
    autocmd!
    " Defer initializing mline until Vim finishes loading startup scripts.
    " This allows for a colorscheme and any dependent plugins to load first.
    autocmd VimEnter * call mline#init()
  augroup END
endif
