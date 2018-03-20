if exists("g:autoloaded_mline") | finish | endif
let g:autoloaded_mline = 1

" This initialization is triggered by a VimEnter autocmd event, which
" occurs after Vim has finished loading vimrc, plugins, packages, etc.
" This allows colorscheme and any external dependencies to load prior
" to statusline configuration. Currently fugitive is the only external
" dependency, though it's optional.
func! mline#init()
  call s:init_statusline()
  call s:init_autocommands()
endf

func! s:init_statusline()
  setg statusline=\                            " space

  setg statusline+=%1*                         " User1 highlight group (filename)
  setg statusline+=%{mline#bufname()}          " relative path
  setg statusline+=%*                          " reset highlight group
  setg statusline+=%{mline#bufname_nc()}       " relative path (non-current)
  setg statusline+=\                           " space

  setg statusline+=%#StatusLineNC#             " StatusLineNC highlight group
  setg statusline+=%{mline#before_filetype()}  " dimmed '['
  setg statusline+=%2*                         " User2 highlight group (filetype)
  setg statusline+=%{mline#filetype()}         " filetype (current)
  setg statusline+=%*                          " reset highlight group
  setg statusline+=%{mline#filetype_nc()}      " filetype (non-current)
  setg statusline+=%#StatusLineNC#             " StatusLineNC highlight group
  setg statusline+=%{mline#after_filetype()}   " dimmed ']'
  setg statusline+=%*                          " reset highlight group
  setg statusline+=\                           " space

  setg statusline+=%w                          " preview
  setg statusline+=%M                          " modified

  setg statusline+=%=                          " separator

  setg statusline+=\                           " space
  setg statusline+=%{toupper(&fenc)}           " encoding

  if exists('g:loaded_fugitive')
    setg statusline+=%(\ \ %{mline#branch()}%) " branch
  endif

  setg statusline+=\ \                         " spaces

  setg statusline+=%l:                         " line:
  setg statusline+=%#StatusLineNC#             " dim
  setg statusline+=%v                          " column
  setg statusline+=%*                          " reset highlight group
  setg statusline+=\                           " space

  redrawstatus | call mline#update_highlight()
endf

func! s:init_autocommands()
  augroup Mline
    autocmd!
    autocmd ColorScheme * call mline#update_highlight()
    autocmd BufWinEnter,BufWritePost,FileWritePost,TextChanged,TextChangedI,WinEnter * call mline#check_modified()
  augroup END
endf

func! mline#current() abort
  return exists('g:actual_curbuf') && bufnr('%') == g:actual_curbuf
endf

func! mline#bufname() abort
  return mline#current() ? bufname('%') : ''
endf
func! mline#bufname_nc() abort
  return !mline#current() ? bufname('%') : ''
endf

func! mline#filetype() abort
  return mline#current() ? &filetype : ''
endf
func! mline#filetype_nc() abort
  return !mline#current() ? &filetype : ''
endf

func! mline#before_filetype() abort
  return strlen(&filetype) ? '[' : ''
endf
func! mline#after_filetype() abort
  return strlen(&filetype) ? ']' : ''
endf

func! mline#branch() abort
  let l:branch = fugitive#head()
  if empty(branch)
    return ''
  else
    return '(' . l:branch . ')'
  endif
endf

let s:highlight_modified = 0

func! mline#check_modified() abort
  if &modified && !s:highlight_modified
    let s:highlight_modified = 1
    call mline#update_highlight()
  elseif !&modified && s:highlight_modified
    let s:highlight_modified = 0
    call mline#update_highlight()
  endif
endf

func! mline#update_highlight() abort
  let l:bg = s:extract_component('StatusLine', 'bg')
  let l:fg = s:extract_component('StatusLine', 'fg')
  let l:colors = filter({'bg': l:bg, 'fg': l:fg}, 'v:val != ""')

  if &modified
    let l:name_style = 'bold,italic'
    let l:type_style = 'italic'
  else
    let l:name_style = 'bold'
    let l:type_style = 'NONE'
  endif

  " StatusLine + name_style
  call s:highlight('User1', l:colors, l:name_style)

  " StatusLine + type_style
  call s:highlight('User2', l:colors, l:type_style)

  " StatusLine + unconditional italics
  call s:highlight('User3', l:colors, 'italic')
endf

function! s:extract_component(group, component) abort
  return synIDattr(synIDtrans(hlID(a:group)), a:component, s:prefix)
endfunction

func! s:highlight(group, colors, style) abort
  let l:dict = extend(a:colors, {'term': a:style})
  let l:spec = s:spec(l:dict)

  execute 'highlight!' a:group l:spec
endf

let s:prefix=has('gui') || has('termguicolors') ? 'gui' : 'cterm'

function! s:spec(highlight) abort
  let l:result=[]
  if has_key(a:highlight, 'bg')
    call insert(l:result, s:prefix . 'bg=' . a:highlight['bg'])
  endif
  if has_key(a:highlight, 'fg')
    call insert(l:result, s:prefix . 'fg=' . a:highlight['fg'])
  endif
  if has_key(a:highlight, 'term')
    call insert(l:result, 'gui='   . a:highlight['term'])
    call insert(l:result, 'cterm=' . a:highlight['term'])
  endif
  return join(l:result, ' ')
endfunction
