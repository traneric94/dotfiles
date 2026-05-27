" Raw Vim training profile.
" Start with: rawvim

set nocompatible
filetype plugin indent on
syntax enable

let mapleader = " "

" Editing basics ----------------------------------------------------------------
set number
set relativenumber
set hidden
set wildmenu
set wildmode=longest:full,full
set path+=**
set suffixesadd=.rb,.go,.py,.js,.jsx,.ts,.tsx,.lua,.md,.json,.yaml,.yml
set ignorecase
set smartcase
set incsearch
set hlsearch
set splitbelow
set splitright
set scrolloff=3
set sidescrolloff=5
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set list
set listchars=tab:\ \ ,trail:.,extends:>,precedes:<,nbsp:+
set colorcolumn=100
set mouse=
set completeopt=menu,preview

if has("clipboard")
  set clipboard=unnamed
endif

" Keep state in Vim's own directories instead of littering project roots.
silent! call mkdir(expand("~/.vim/undo"), "p")
silent! call mkdir(expand("~/.vim/swap"), "p")
silent! call mkdir(expand("~/.vim/backup"), "p")
set undofile
set undodir=~/.vim/undo//
set directory=~/.vim/swap//
set backupdir=~/.vim/backup//

" Search, quickfix, tags ---------------------------------------------------------
if executable("rg")
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --glob\ '!.git'
  set grepformat=%f:%l:%c:%m
endif

set tags=./tags;,tags;

command! -nargs=* Rg silent grep! <args> | copen
command! Tags silent !ctags -R --exclude=.git --exclude=node_modules --exclude=vendor --exclude=tmp .

" netrw -------------------------------------------------------------------------
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1

" Muscle-memory mappings --------------------------------------------------------
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>n :nohlsearch<CR>
nnoremap <leader>e :Explore<CR>
nnoremap <leader>v :Vexplore<CR>
nnoremap <leader>s :split<CR>
nnoremap <leader>\ :vsplit<CR>

nnoremap <leader>b :ls<CR>:buffer<Space>
nnoremap <leader><leader> <C-^>

nnoremap <leader>g :Rg <C-r><C-w><CR>
nnoremap <leader>G :Rg<Space>
nnoremap <leader>m :make<CR>
nnoremap <leader>c :copen<CR>
nnoremap <leader>x :cclose<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>

nnoremap <leader>t :Tags<CR>
nnoremap <leader>] g<C-]>
nnoremap <leader>[ <C-t>

" Filetype defaults -------------------------------------------------------------
augroup rawvim_filetypes
  autocmd!
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4 makeprg=go\ test\ ./...
  autocmd FileType python setlocal makeprg=python3\ -m\ pytest
  autocmd FileType ruby setlocal makeprg=bundle\ exec\ rspec
  autocmd FileType javascript,typescript,javascriptreact,typescriptreact setlocal makeprg=npm\ test
augroup END
