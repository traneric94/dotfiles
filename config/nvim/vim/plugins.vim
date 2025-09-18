" Auto-install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins
call plug#begin('~/.config/nvim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'scrooloose/nerdtree'
Plug 'terryma/vim-multiple-cursors'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'sheerun/vim-polyglot'
" Enhanced syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
" LSP and completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" AI assistance
Plug 'github/copilot.vim'
" Navigation and search
Plug 'nvim-lua/plenary.nvim'
Plug 'ThePrimeagen/harpoon'
Plug 'nvim-telescope/telescope.nvim'
" Git integration
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'  " GitHub support for fugitive
Plug 'lewis6991/gitsigns.nvim'
call plug#end()

" Airline settings
let g:airline#extensions#tabline#enabled = 2
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#right_sep = ' '
let g:airline#extensions#tabline#right_alt_sep = '|'
let g:airline_left_sep = ' '
let g:airline_left_alt_sep = '|'
let g:airline_right_sep = ' '
let g:airline_right_alt_sep = '|'
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#buffer_idx_mode = 1

" Use a compatible dark airline theme that works well with Catppuccin
let g:airline_theme = 'dark'

" Multicursor settings
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-e>'
let g:multi_cursor_quit_key='<Esc>'

" NERDTree settings
let NERDTreeShowHidden=1
let g:NERDTreeChDirMode=2
let g:NERDTreeAutoDeleteBuffer=1
let g:NERDTreeMinimalUI=1
let g:NERDTreeDirArrows=1

" CoC settings
" Enhanced CoC semantic tokens (disabled for Go to allow custom highlighting)
call coc#config('semanticTokens.enable', v:true)
call coc#config('semanticTokens.filetypes', ['javascript', 'typescript', 'typescriptreact', 'python', 'ruby', 'rust', 'lua'])

" Auto-install useful language servers
let g:coc_global_extensions = [
  \ 'coc-pyright',
  \ 'coc-tsserver',
  \ 'coc-go',
  \ 'coc-rust-analyzer',
  \ 'coc-solargraph',
  \ 'coc-json',
  \ 'coc-yaml',
  \ 'coc-html',
  \ 'coc-css',
  \ 'coc-prettier',
  \ 'coc-eslint',
  \ 'coc-docker'
\ ]