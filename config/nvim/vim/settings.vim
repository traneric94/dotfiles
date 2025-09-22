" Basic vim settings
syntax on
set ruler                       " Show the line and column numbers of the cursor.
set formatoptions+=o            " Continue comment marker in new lines.
set nowrap                      " do not automatically wrap on load
set formatoptions-=t            " do not automatically wrap text when typing
set modeline                    " Enable modeline.
set linespace=0                 " Set line-spacing to minimum.
set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
" More natural splits
set splitbelow                  " Horizontal split below current.
set splitright                  " Vertical split to right of current.
set scrolloff=3                 " Show next 3 lines while scrolling.
set sidescrolloff=5             " Show next 5 columns while side-scrollin.
set nostartofline               " Do not jump to first character with page commands.
set noerrorbells                " No beeps
set backspace=indent,eol,start  " Makes backspace key more powerful.
set showcmd                     " Show me what I'm typing
set showmode                    " Show current mode.
set noswapfile                  " Don't use swapfile
set nobackup            	    " Don't create annoying backup files
set encoding=utf-8              " Set default encoding to UTF-8
set autowrite                   " Automatically save before :next, :make etc.
set autoread                    " Automatically reread changed files without asking me anything
set laststatus=2
set fileformats=unix,dos,mac    " Prefer Unix over Windows over OS 9 formats
set showmatch                   " Do not show matching brackets by flickering
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not when search pattern contains upper case characters
set autoindent
set tabstop=2 shiftwidth=2 expandtab
set gdefault                    " Use 'g' flag by default with :s/foo/bar/.
set magic                       " Use 'magic' patterns (extended regular expressions).
set number                      " Set line numbers
set relativenumber              " Enable relative line numbers (hybrid mode)
set clipboard=unnamed           " Use system clipboard
set colorcolumn=100              " Set max line length

" Other
set mouse=a
set list
set listchars=tab:\ \ ,trail:·,extends:»,precedes:«,nbsp:⣿

" Preview window settings
set previewheight=12
set completeopt=menu,menuone,preview,noselect

" Use ripgrep as default grep program
set grepprg=rg\ --vimgrep\ --smart-case
set grepformat=%f:%l:%c:%m

" Folding configuration
set foldenable                " Enable folding
set foldlevel=2               " Start with folds open up to level 2
set foldmethod=manual         " Use manual folding for import auto-folding
set foldcolumn=1              " Show fold indicators in gutter

" Language-specific settings
let g:python_host_prog="/usr/local/bin/python3.9"

" Go make configuration
autocmd FileType go setlocal makeprg=make
autocmd FileType go setlocal errorformat=%E%f:%l:%c:\ %m,%E%f:%l:\ %m,%-G%.%#

" Ruby configuration
let g:ruby_indent_assignment_style = 'variable'
let g:ruby_indent_block_style = 'do'
let g:ruby_space_errors = 1
let g:ruby_operators = 1

" React Native / TSX configuration
let g:typescript_indent_disable = 0

" Simplified Go highlighting (treesitter handles most syntax)
let g:go_highlight_types = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1

" Session settings
let g:session_autosave = 'yes'
let g:session_autoload = 'yes'
let g:session_default_to_last = 1