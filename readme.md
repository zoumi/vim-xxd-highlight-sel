# vim-xxd-highlight-sel

Show cursor position or selected data in corresponding HEX/ASCII area in vim's xxd buffer.


## Overview

Normal mode:


Visual block mode:


Visual line mode:


## Minimal working example

Minimal working configuration using [vim-plug](https://github.com/junegunn/vim-plug).

```vim
set nocompatible
filetype plugin indent on

call plug#begin('~/.vim/plugged')
  Plug 'zoumi/vim-xxd-highlight-sel'
call plug#end()

```

## Recommanded working example

Recommanded working configuration using [vim-plug](https://github.com/junegunn/vim-plug).
```vim
set nocompatible
filetype plugin indent on

call plug#begin('~/.vim/plugged')
  Plug 'fidian/hexmode',{'on':'Hexmode'}
  nnoremap <C-H> :Hexmode<CR>
  Plug 'zoumi/vim-xxd-highlight-sel'
call plug#end()

```
