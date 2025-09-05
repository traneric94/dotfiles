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
let NERDTreeShowHidden=1
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
" Airline theme will be set after colorscheme is loaded
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


" LSP keybindings
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <leader>rn <Plug>(coc-rename)
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

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

" Other
set mouse=
set list
set listchars=tab:\ \ ,trail:·,extends:»,precedes:«,nbsp:⣿

" Buffer handling
nmap <leader>l :bnext<CR>
nmap <c-h> :bprevious<CR>
nmap <leader>bq :bp <BAR> bd #<CR>
nmap <leader>bl :ls<CR>
nmap <leader>n :e ~/.config/nvim/init.vim<CR>
nmap <leader>r :source ~/.config/nvim/init.vim<CR>:echo "Config reloaded!"<CR>

" Auto-reload config on save
augroup config_reload
  autocmd!
  autocmd BufWritePost ~/.config/nvim/init.vim source ~/.config/nvim/init.vim | echo "Config auto-reloaded!"
augroup END

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
call plug#end()

" Catppuccin configuration (only if plugin is installed)
lua << EOF
local status_ok, catppuccin = pcall(require, "catppuccin")
if status_ok then
  catppuccin.setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "latte",
        dark = "mocha",
    },
    transparent_background = false,
    show_end_of_buffer = false,
    term_colors = true,
    dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
    },
    integrations = {
        coc_nvim = true,
        telescope = true,
        harpoon = true,
        native_lsp = {
            enabled = true,
            underlines = {
                errors = { "undercurl" },
                hints = { "undercurl" },
                warnings = { "undercurl" },
                information = { "undercurl" },
            },
            inlay_hints = {
                background = true,
            },
        },
        treesitter = true,
        semantic_tokens = true,
    },
    custom_highlights = function(colors)
      return {
        -- LSP and CoC highlighting
        CocErrorSign = { fg = colors.red },
        CocWarningSign = { fg = colors.yellow },
        CocInfoSign = { fg = colors.sky },
        CocHintSign = { fg = colors.teal },
        CocErrorHighlight = { bg = colors.none, sp = colors.red, undercurl = true },
        CocWarningHighlight = { bg = colors.none, sp = colors.yellow, undercurl = true },
        CocInfoHighlight = { bg = colors.none, sp = colors.sky, undercurl = true },
        CocHintHighlight = { bg = colors.none, sp = colors.teal, undercurl = true },
        -- Enhanced semantic highlighting
        CocSemClass = { fg = colors.yellow, style = { "bold" } },
        CocSemEnum = { fg = colors.peach },
        CocSemInterface = { fg = colors.yellow, style = { "italic" } },
        CocSemStruct = { fg = colors.yellow, style = { "bold" } },
        CocSemType = { fg = colors.yellow },
        CocSemTypeParameter = { fg = colors.maroon, style = { "italic" } },
        CocSemVariable = { fg = colors.text },
        CocSemParameter = { fg = colors.maroon, style = { "italic" } },
        CocSemEnumMember = { fg = colors.teal },
        CocSemFunction = { fg = colors.blue, style = { "bold" } },
        CocSemMethod = { fg = colors.blue, style = { "bold" } },
        CocSemProperty = { fg = colors.teal },
        CocSemKeyword = { fg = colors.mauve, style = { "bold" } },
        CocSemModifier = { fg = colors.mauve },
        CocSemNamespace = { fg = colors.pink, style = { "italic" } },
        CocSemOperator = { fg = colors.sky },
        CocSemComment = { fg = colors.overlay1, style = { "italic" } },
        CocSemString = { fg = colors.green },
        CocSemNumber = { fg = colors.peach },
        CocSemRegexp = { fg = colors.pink },
        CocSemDecorator = { fg = colors.pink },
        -- Treesitter enhancements
        ["@function"] = { fg = colors.blue, style = { "bold" } },
        ["@function.builtin"] = { fg = colors.sky, style = { "bold" } },
        ["@method"] = { fg = colors.blue, style = { "bold" } },
        ["@parameter"] = { fg = colors.maroon, style = { "italic" } },
        ["@variable"] = { fg = colors.text },
        ["@variable.builtin"] = { fg = colors.red, style = { "italic" } },
        ["@field"] = { fg = colors.teal },
        ["@property"] = { fg = colors.teal },
        -- Enhanced type differentiation
        ["@type"] = { fg = colors.yellow },
        ["@type.builtin"] = { fg = colors.peach, style = { "bold" } }, -- string, int, bool
        ["@type.definition"] = { fg = colors.yellow, style = { "bold" } }, -- struct definitions
        ["@type.qualifier"] = { fg = colors.mauve }, -- const, var keywords
        ["@constructor"] = { fg = colors.sapphire },
        ["@constant"] = { fg = colors.peach, style = { "bold" } },
        ["@constant.builtin"] = { fg = colors.flamingo, style = { "bold" } }, -- true, false, nil
        ["@number"] = { fg = colors.peach },
        ["@number.float"] = { fg = colors.peach, style = { "italic" } },
        ["@boolean"] = { fg = colors.flamingo, style = { "bold" } },
        ["@string"] = { fg = colors.green },
        ["@string.escape"] = { fg = colors.pink },
        ["@character"] = { fg = colors.teal },
        ["@comment"] = { fg = colors.overlay1, style = { "italic" } },
        ["@keyword"] = { fg = colors.mauve, style = { "bold" } },
        ["@keyword.function"] = { fg = colors.mauve, style = { "bold" } },
        ["@keyword.operator"] = { fg = colors.mauve },
        ["@keyword.return"] = { fg = colors.pink, style = { "bold" } },
        ["@keyword.import"] = { fg = colors.pink },
        ["@operator"] = { fg = colors.sky },
        ["@punctuation"] = { fg = colors.overlay2 },
        ["@punctuation.delimiter"] = { fg = colors.overlay2 },
        ["@punctuation.bracket"] = { fg = colors.overlay2 },
        ["@punctuation.special"] = { fg = colors.sky },
        -- Go-specific enhancements
        ["@namespace"] = { fg = colors.pink, style = { "italic" } },
        ["@label"] = { fg = colors.sapphire, style = { "italic" } },
        ["@tag"] = { fg = colors.mauve },
        ["@tag.attribute"] = { fg = colors.teal },
        ["@tag.delimiter"] = { fg = colors.overlay2 },
      }
    end,
  })
end
EOF

" Set Catppuccin colorscheme
silent! colorscheme catppuccin

" Use a compatible dark airline theme that works well with Catppuccin
let g:airline_theme = 'dark'

" Telescope setup with enhanced mappings
lua << EOF
require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        -- Navigation
        ["<C-j>"] = require('telescope.actions').move_selection_next,
        ["<C-k>"] = require('telescope.actions').move_selection_previous,
        
        -- Send to qflist  
        ["<C-q>"] = require('telescope.actions').send_to_qflist + require('telescope.actions').open_qflist,
        ["<M-q>"] = require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist,
        
        -- Preview scrolling
        ["<C-u>"] = require('telescope.actions').preview_scrolling_up,
        ["<C-d>"] = require('telescope.actions').preview_scrolling_down,
        
        -- Split options
        ["<C-x>"] = require('telescope.actions').select_horizontal,
        ["<C-v>"] = require('telescope.actions').select_vertical,
        ["<C-t>"] = require('telescope.actions').select_tab,
      },
      n = {
        -- Same mappings for normal mode
        ["<C-q>"] = require('telescope.actions').send_to_qflist + require('telescope.actions').open_qflist,
        ["<M-q>"] = require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist,
        ["<C-x>"] = require('telescope.actions').select_horizontal,
        ["<C-v>"] = require('telescope.actions').select_vertical,
        ["<C-t>"] = require('telescope.actions').select_tab,
      },
    },
  },
}
EOF

" Telescope key mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Additional useful telescope mappings
nnoremap <leader>fr <cmd>Telescope oldfiles<cr>
nnoremap <leader>fc <cmd>Telescope git_commits<cr>
nnoremap <leader>fs <cmd>Telescope git_status<cr>

" Use ripgrep as default grep program
set grepprg=rg\ --vimgrep\ --smart-case
set grepformat=%f:%l:%c:%m

" Grep mappings
nnoremap <leader>g :grep<space>
nnoremap <leader>G :grep <C-r><C-w><CR>

" Quickfix list mappings
nnoremap <leader>co <cmd>copen<cr>
nnoremap <leader>cc <cmd>cclose<cr>
nnoremap ]q <cmd>cnext<cr>
nnoremap [q <cmd>cprev<cr>
nnoremap ]Q <cmd>clast<cr>
nnoremap [Q <cmd>cfirst<cr>

" Test toggle function for all languages in Chime codebase
function! ToggleTestFile()
  let current_file = expand('%:p')
  let file_dir = expand('%:p:h')
  let file_name = expand('%:t:r')
  let file_ext = expand('%:e')
  
  " Ruby patterns (chime-atlas, Ruby services)
  if file_ext ==# 'rb'
    if current_file =~# '_spec\.rb$'
      " spec -> source
      let source_file = substitute(current_file, '_spec\.rb$', '.rb', '')
      let source_file = substitute(source_file, '/spec/', '/lib/', '')
      let source_file = substitute(source_file, '/spec/', '/app/', '')
    elseif current_file =~# '_test\.rb$'
      " test -> source  
      let source_file = substitute(current_file, '_test\.rb$', '.rb', '')
      let source_file = substitute(source_file, '/test/', '/lib/', '')
    else
      " source -> spec (prefer RSpec)
      let spec_file1 = substitute(current_file, '\.rb$', '_spec.rb', '')
      let spec_file1 = substitute(spec_file1, '/lib/', '/spec/', '')
      let spec_file1 = substitute(spec_file1, '/app/', '/spec/', '')
      let spec_file2 = substitute(current_file, '\.rb$', '_test.rb', '')
      let spec_file2 = substitute(spec_file2, '/lib/', '/test/', '')
      
      if filereadable(spec_file1)
        let source_file = spec_file1
      elseif filereadable(spec_file2)  
        let source_file = spec_file2
      else
        let source_file = spec_file1  " Create RSpec by default
      endif
    endif
    
  " TypeScript/React Native patterns (project-otter)
  elseif file_ext ==# 'ts' || file_ext ==# 'tsx' || file_ext ==# 'js' || file_ext ==# 'jsx'
    if current_file =~# '\.test\.\(ts\|tsx\|js\|jsx\)$'
      " test -> source
      let source_file = substitute(current_file, '\.test\.', '.', '')
    elseif current_file =~# '\.spec\.\(ts\|tsx\|js\|jsx\)$'
      " spec -> source
      let source_file = substitute(current_file, '\.spec\.', '.', '')
    else
      " source -> test (prefer .test. pattern)
      let test_file = substitute(current_file, '\.\(ts\|tsx\|js\|jsx\)$', '.test.\1', '')
      let spec_file = substitute(current_file, '\.\(ts\|tsx\|js\|jsx\)$', '.spec.\1', '')
      
      if filereadable(test_file)
        let source_file = test_file
      elseif filereadable(spec_file)
        let source_file = spec_file  
      else
        let source_file = test_file  " Create .test. by default
      endif
    endif
    
  " Go patterns (braze-gateway, other Go services)
  elseif file_ext ==# 'go'
    if current_file =~# '_test\.go$'
      " test -> source
      let source_file = substitute(current_file, '_test\.go$', '.go', '')
    else
      " source -> test
      let source_file = substitute(current_file, '\.go$', '_test.go', '')
    endif
    
  " Python patterns  
  elseif file_ext ==# 'py'
    if current_file =~# '^test_.*\.py$' || current_file =~# '_test\.py$'
      " test -> source
      let source_file = substitute(current_file, '^test_', '', '')
      let source_file = substitute(source_file, '_test\.py$', '.py', '')
    else
      " source -> test (prefer test_ prefix)
      let test_file1 = 'test_' . expand('%:t')
      let test_file2 = substitute(current_file, '\.py$', '_test.py', '')
      
      if filereadable(file_dir . '/' . test_file1)
        let source_file = file_dir . '/' . test_file1
      elseif filereadable(test_file2)
        let source_file = test_file2
      else
        let source_file = file_dir . '/' . test_file1  " Create test_ by default
      endif
    endif
    
  else
    echo "Unknown file type for test toggle: " . file_ext
    return
  endif
  
  " Open the target file
  if filereadable(source_file)
    execute 'edit ' . fnameescape(source_file)
    echo "Switched to: " . fnamemodify(source_file, ':t')
  else
    " Create the test file with basic template
    execute 'edit ' . fnameescape(source_file)
    echo "Created new test file: " . fnamemodify(source_file, ':t')
    
    " Add basic templates based on file type
    if source_file =~# '_spec\.rb$'
      call append(0, ["require 'rails_helper'", "", "RSpec.describe " . substitute(file_name, '_spec$', '', '') . " do", "  pending \"add some examples to (or delete) " . expand('%:t') . "\"", "end"])
    elseif source_file =~# '\.test\.\(ts\|tsx\)$'
      call append(0, ["import { describe, it, expect } from '@jest/globals';", "", "describe('" . file_name . "', () => {", "  it('should work', () => {", "    expect(true).toBe(true);", "  });", "});"])
    elseif source_file =~# '_test\.go$'
      let package_name = substitute(file_dir, '.*/', '', '')
      call append(0, ["package " . package_name, "", "import \"testing\"", "", "func Test" . substitute(file_name, '_test$', '', '') . "(t *testing.T) {", "  // TODO: implement test", "}"])
    elseif source_file =~# '\.py$' && source_file =~# 'test_'
      call append(0, ["import unittest", "", "class Test" . substitute(substitute(file_name, '^test_', '', ''), '_', '', 'g') . "(unittest.TestCase):", "    def test_example(self):", "        self.assertTrue(True)", "", "if __name__ == '__main__':", "    unittest.main()"])
    endif
  endif
endfunction

" Test toggle keybinding
nnoremap <leader>tt <cmd>call ToggleTestFile()<cr>

" Go formatting function
function! GoFormat()
  if &filetype == 'go'
    " First run goimports to remove unused imports and add missing ones
    let goimports_cmd = "~/go/bin/goimports -w " . shellescape(expand('%'))
    let goimports_result = system(goimports_cmd)
    if v:shell_error != 0
      return
    endif
    
    " Then run gci to group imports properly
    let cmd = "~/go/bin/gci write --skip-generated --skip-vendor -s standard -s default -s \"prefix(github.com/1debit)\" " . shellescape(expand('%'))
    let result = system(cmd)
    edit
  endif
endfunction

" Go formatting and import management on save (3-group imports like chime-go-atlas)
augroup go_format
  autocmd!
  autocmd BufWritePost *.go call GoFormat()
augroup END

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

" Make netrw change working directory
augroup netrw_follow
  autocmd!
  autocmd FileType netrw setlocal autochdir
augroup END

" Override CoC signs after it loads (less intrusive symbols)
augroup coc_signs
  autocmd!
  autocmd User CocNvimInit call SetupCocSigns()
  autocmd VimEnter * call SetupCocSigns()
augroup END

function! SetupCocSigns()
  sign define CocError text=● texthl=CocErrorSign linehl= numhl=
  sign define CocWarning text=● texthl=CocWarningSign linehl= numhl=  
  sign define CocInfo text=● texthl=CocInfoSign linehl= numhl=
  sign define CocHint text=● texthl=CocHintSign linehl= numhl=
endfunction

" Configure Treesitter for enhanced syntax highlighting
lua << EOF
local status_ok, treesitter = pcall(require, "nvim-treesitter.configs")
if status_ok then
  treesitter.setup {
    ensure_installed = { "go", "javascript", "typescript", "tsx", "python", "ruby", "lua", "vim", "yaml", "json", "html", "css", "bash", "dockerfile", "rust", "toml" },
    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["as"] = "@scope",
        },
      },
    },
  }
end
EOF

" Enhanced CoC semantic tokens (disabled for Go to allow custom highlighting)
call coc#config('semanticTokens.enable', v:true)
call coc#config('semanticTokens.filetypes', ['javascript', 'typescript', 'typescriptreact', 'python', 'ruby', 'rust', 'lua'])

" Ruby configuration
let g:ruby_indent_assignment_style = 'variable'
let g:ruby_indent_block_style = 'do'
let g:ruby_space_errors = 1
let g:ruby_operators = 1

" React Native / TSX configuration
let g:typescript_indent_disable = 0

" Enable more colorful Go syntax
let g:go_highlight_functions = 1
let g:go_highlight_function_parameters = 1  
let g:go_highlight_function_calls = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_variable_assignments = 1
let g:go_highlight_variable_declarations = 1

" Additional Go type highlighting with higher priority
augroup go_highlights
  autocmd!
  " Apply after all other highlighting loads
  autocmd FileType go call SetupGoHighlights()
  autocmd ColorScheme * if &filetype == 'go' | call SetupGoHighlights() | endif
augroup END

function! SetupGoHighlights()
  " Disable treesitter for specific types temporarily
  if exists('b:ts_highlight')
    TSBufDisable highlight
    TSBufEnable highlight
  endif
  
  " Clear existing matches
  silent! call clearmatches()
  
  " Use matchadd for higher priority (above treesitter)
  call matchadd('GoStringTypeCustom', '\<string\>', 100)
  call matchadd('GoBoolTypeCustom', '\<bool\>', 100) 
  call matchadd('GoIntTypeCustom', '\<\(int\|int8\|int16\|int32\|int64\|uint\|uint8\|uint16\|uint32\|uint64\|uintptr\|byte\|rune\)\>', 100)
  call matchadd('GoFloatTypeCustom', '\<\(float32\|float64\|complex64\|complex128\)\>', 100)
  call matchadd('GoBoolValueCustom', '\<\(true\|false\)\>', 100)
  call matchadd('GoNilCustom', '\<nil\>', 100)
  
  " Define highlight groups with very specific colors
  highlight! GoStringTypeCustom guifg=#a6e3a1 gui=bold cterm=bold ctermfg=green
  highlight! GoBoolTypeCustom guifg=#fab387 gui=bold cterm=bold ctermfg=yellow
  highlight! GoIntTypeCustom guifg=#f9e2af gui=bold cterm=bold ctermfg=blue  
  highlight! GoFloatTypeCustom guifg=#cba6ac gui=bold,italic cterm=bold ctermfg=magenta
  highlight! GoBoolValueCustom guifg=#f2cdcd gui=bold cterm=bold ctermfg=red
  highlight! GoNilCustom guifg=#f38ba8 gui=bold cterm=bold ctermfg=red
endfunction

" Define Catppuccin colors for syntax linking
highlight CatppuccinPeach guifg=#fab387 ctermfg=215
highlight CatppuccinYellow guifg=#f9e2af ctermfg=229
highlight CatppuccinPink guifg=#f5c2e7 ctermfg=218
highlight CatppuccinFlamingo guifg=#f2cdcd ctermfg=217
highlight CatppuccinRed guifg=#f38ba8 ctermfg=203

" Folding configuration
set foldenable                " Enable folding
set foldlevel=2               " Start with folds open up to level 2
set foldmethod=manual         " Use manual folding for import auto-folding
set foldcolumn=1              " Show fold indicators in gutter

" Folding keybindings
nnoremap <leader>za za        " Toggle fold under cursor
nnoremap <leader>zM zM        " Close all folds
nnoremap <leader>zR zR        " Open all folds
nnoremap <leader>zm zm        " Increase fold level (close more folds)
nnoremap <leader>zr zr        " Decrease fold level (open more folds)

" Auto-fold imports function
function! AutoFoldImports()
  let current_line = 1
  let total_lines = line('$')
  
  " Clear existing manual folds
  normal! zE
  
  while current_line <= total_lines
    let line_content = getline(current_line)
    
    " Detect import blocks for different languages
    if &filetype == 'go'
      " Go imports: look for "import (" block
      if line_content =~ '^\s*import\s*('
        let import_start = current_line
        let current_line = current_line + 1
        
        " Find the end of import block
        while current_line <= total_lines && getline(current_line) !~ '^\s*)'
          let current_line = current_line + 1
        endwhile
        
        if current_line <= total_lines
          " Create fold for import block
          execute import_start . ',' . current_line . 'fold'
        endif
      endif
      
    elseif &filetype == 'typescript' || &filetype == 'typescriptreact' || &filetype == 'javascript' || &filetype == 'javascriptreact'
      " TypeScript/JavaScript imports
      if line_content =~ '^\s*import\s\+.*from'
        let import_start = current_line
        
        " Find consecutive import lines
        while current_line + 1 <= total_lines && getline(current_line + 1) =~ '^\s*import\s\+.*from'
          let current_line = current_line + 1
        endwhile
        
        " Create fold if there are multiple consecutive imports
        if current_line > import_start
          execute import_start . ',' . current_line . 'fold'
        endif
      endif
      
    elseif &filetype == 'ruby'
      " Ruby requires
      if line_content =~ '^\s*require'
        let import_start = current_line
        
        " Find consecutive require lines
        while current_line + 1 <= total_lines && getline(current_line + 1) =~ '^\s*require'
          let current_line = current_line + 1
        endwhile
        
        " Create fold if there are multiple consecutive requires
        if current_line > import_start
          execute import_start . ',' . current_line . 'fold'
        endif
      endif
      
    elseif &filetype == 'python'
      " Python imports
      if line_content =~ '^\s*\(import\|from\)\s'
        let import_start = current_line
        
        " Find consecutive import lines
        while current_line + 1 <= total_lines && getline(current_line + 1) =~ '^\s*\(import\|from\)\s'
          let current_line = current_line + 1
        endwhile
        
        " Create fold if there are multiple consecutive imports
        if current_line > import_start
          execute import_start . ',' . current_line . 'fold'
        endif
      endif
    endif
    
    let current_line = current_line + 1
  endwhile
endfunction

" Auto-fold imports on file open and save
augroup auto_fold_imports
  autocmd!
  autocmd BufReadPost,BufWritePost *.go,*.ts,*.tsx,*.js,*.jsx,*.rb,*.py call AutoFoldImports()
augroup END

" Manual command to fold imports
command! FoldImports call AutoFoldImports()

