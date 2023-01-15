if has('nvim')
    "nvim is not supported currently
    finish
endif
" check whether this script is already loaded
if exists("g:loaded_xxd_hightlight_sel")
  finish
endif

let g:loaded_xxd_hightlight_sel = 1

augroup xxd_highlight_sel_augroup 
    autocmd!
    autocmd FileType xxd call xxd_highlight_sel#init()
augroup END
