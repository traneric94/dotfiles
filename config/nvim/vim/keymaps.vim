" Leader key configuration
let mapleader=' '

" Search and Replace
nmap <Leader>s :%s//g<Left><Left>

" Basic movement and editing
nmap <Space> <PageDown>
vmap <BS> x

" Use <C-L> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
endif

" Smooth scrolling with Shift+hjkl
nnoremap <S-j> <C-E>
nnoremap <S-k> <C-Y>
nnoremap <S-h> zh
nnoremap <S-l> zl

" NERDTree mappings
map <C-n> :NERDTreeFind<CR>
nmap <Leader>nr :NERDTreeFocus<cr>R<c-w><c-p>
nnoremap <leader>nf :NERDTreeFind<CR>

" Git mappings
nnoremap <leader>gg :Git<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gc :Git commit<CR>
nnoremap <leader>gb :GBrowse<CR>
vnoremap <leader>gb :GBrowse<CR>
nnoremap <leader>bb :lua require('gitsigns').toggle_current_line_blame()<CR>
nnoremap <leader>gp :call OpenPullRequest()<CR>

" Airline tab navigation
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

" LSP keybindings (CoC)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <leader>rn <Plug>(coc-rename)
nnoremap <silent> K :call ShowDocumentation()<CR>
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Buffer handling
nmap <leader>l :bnext<CR>
nmap <c-h> :bprevious<CR>
nmap <leader>bq :bp <BAR> bd #<CR>
nmap <leader>bl :ls<CR>
nmap <leader>n :e ~/.config/nvim/init.vim<CR>
nmap <leader>r :source ~/.config/nvim/init.vim<CR>:echo "Config reloaded!"<CR>

" Telescope key mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Additional telescope mappings
nnoremap <leader>fr <cmd>Telescope oldfiles<cr>
nnoremap <leader>fc <cmd>Telescope git_commits<cr>
nnoremap <leader>fs <cmd>Telescope git_status<cr>

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

" Test toggle keybinding
nnoremap <leader>tt <cmd>call ToggleTestFile()<cr>

" Harpoon key mappings
nnoremap <leader>a <cmd>lua require("harpoon.mark").add_file()<cr>
nnoremap <leader>h <cmd>lua require("harpoon.ui").toggle_quick_menu()<cr>
nnoremap <leader>m1 <cmd>lua require("harpoon.ui").nav_file(1)<cr>
nnoremap <leader>m2 <cmd>lua require("harpoon.ui").nav_file(2)<cr>
nnoremap <leader>m3 <cmd>lua require("harpoon.ui").nav_file(3)<cr>
nnoremap <leader>m4 <cmd>lua require("harpoon.ui").nav_file(4)<cr>

" Simple vsplit telescope mappings
nnoremap <leader>vf <cmd>vsplit<cr><cmd>Telescope find_files<cr>
nnoremap <leader>vg <cmd>vsplit<cr><cmd>Telescope live_grep<cr>
nnoremap <leader>vb <cmd>vsplit<cr><cmd>Telescope buffers<cr>