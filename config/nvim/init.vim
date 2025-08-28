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
set clipboard=unnamed           " Use system clipboard
set rnu!                        " Enable relative line numbers
set nu!
set colorcolumn=100              " Set max line length

" Search and Replace
nmap <Leader>s :%s//g<Left><Left>

" Leader key is like a command prefix. 
let mapleader=' '


" set cursorcolumn
nmap <Space> <PageDown>
vmap <BS> x

" nerdtree config
map <C-n> :NERDTreeToggle<CR>
nmap <Leader>r :NERDTreeFocus<cr>R<c-w><c-p>
" airline settings
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
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>0 <Plug>AirlineSelectTab0
nmap <leader>- <Plug>AirlineSelectPrevTab
nmap <leader>+ <Plug>AirlineSelectNextTab

" Multicursor
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-e>'
let g:multi_cursor_quit_key='<Esc>'

" coc.nvim config
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Other
set mouse=
set list

" Buffer handling
nmap L :let &number=1-&number<CR>
nmap <leader>l :bnext<CR>
nmap <c-h> :bprevious<CR>
nmap <leader>bq :bp <BAR> bd #<CR>
nmap <leader>bl :ls<CR>
nmap <leader>n :set invnumber<CR>

" Use <C-L> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
endif


let g:python_host_prog="/usr/local/bin/python3.9"

let g:session_autosave = 'yes'
let g:session_autoload = 'yes'
let g:session_default_to_last = 1

" Auto-install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Smart relative line number toggle
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

" Plugins here
call plug#begin('~/.config/nvim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'scrooloose/nerdtree'
Plug 'terryma/vim-multiple-cursors'
Plug 'dracula/vim'
Plug 'sheerun/vim-polyglot'
" LSP and completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" AI assistance
Plug 'github/copilot.vim'
" Navigation and search
Plug 'nvim-lua/plenary.nvim'
Plug 'ThePrimeagen/harpoon'
Plug 'nvim-telescope/telescope.nvim'
call plug#end()

colorscheme dracula

" Telescope key mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Telescope Lua alternatives (same keybindings, different implementation)
" nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
" nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
" nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
" nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

" Harpoon key mappings for quick file navigation
nnoremap <leader>a <cmd>lua require("harpoon.mark").add_file()<cr>
nnoremap <leader>h <cmd>lua require("harpoon.ui").toggle_quick_menu()<cr>
nnoremap <leader>m1 <cmd>lua require("harpoon.ui").nav_file(1)<cr>
nnoremap <leader>m2 <cmd>lua require("harpoon.ui").nav_file(2)<cr>
nnoremap <leader>m3 <cmd>lua require("harpoon.ui").nav_file(3)<cr>
nnoremap <leader>m4 <cmd>lua require("harpoon.ui").nav_file(4)<cr>

" Lua functions for telescope vsplit integration
lua << EOF
function telescope_find_files_vsplit()
  if vim.bo.filetype == 'nerdtree' then
    require('telescope.builtin').find_files({
      attach_mappings = function(_, map)
        map('i', '<CR>', require('telescope.actions').file_vsplit)
        map('n', '<CR>', require('telescope.actions').file_vsplit)
        return true
      end
    })
  else
    require('telescope.builtin').find_files()
  end
end

function telescope_live_grep_vsplit()
  if vim.bo.filetype == 'nerdtree' then
    require('telescope.builtin').live_grep({
      attach_mappings = function(_, map)
        map('i', '<CR>', require('telescope.actions').file_vsplit)
        map('n', '<CR>', require('telescope.actions').file_vsplit)
        return true
      end
    })
  else
    require('telescope.builtin').live_grep()
  end
end

function telescope_buffers_vsplit()
  if vim.bo.filetype == 'nerdtree' then
    require('telescope.builtin').buffers({
      attach_mappings = function(_, map)
        map('i', '<CR>', require('telescope.actions').file_vsplit)
        map('n', '<CR>', require('telescope.actions').file_vsplit)
        return true
      end
    })
  else
    require('telescope.builtin').buffers()
  end
end
EOF

" Custom telescope mappings (vsplit when in NERDTree)
nnoremap <leader>vf <cmd>lua telescope_find_files_vsplit()<CR>
nnoremap <leader>vg <cmd>lua telescope_live_grep_vsplit()<CR>
nnoremap <leader>vb <cmd>lua telescope_buffers_vsplit()<CR>

" Load telescope harpoon extension after plugins are loaded
augroup telescope_harpoon
  autocmd!
  autocmd VimEnter * silent! lua require("telescope").load_extension('harpoon')
augroup END

