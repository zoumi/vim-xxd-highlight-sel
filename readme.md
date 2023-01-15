# vim-xxd-highlight-sel

Show cursor position or selected data in corresponding HEX/ASCII area in vim's xxd buffer.


## Overview

Normal mode:
![NOMAL](https://user-images.githubusercontent.com/5162901/212532184-4e8aa613-16d4-44a9-8f1a-45e502d88d37.gif)


Visual block mode:
![visualb](https://user-images.githubusercontent.com/5162901/212532194-93f73278-8e5d-4753-96d8-a7a41f21aecf.gif)


Visual line mode:
![visuall](https://user-images.githubusercontent.com/5162901/212532200-999c2674-34d1-4187-a86e-d20b3007597b.gif)


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
