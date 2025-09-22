" Auto-follow and startup behavior for NERDTree
augroup nerdtree_follow
  autocmd!
  " Close NERDTree if it's the last window
  autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | q | endif

  " Open NERDTree automatically when nvim starts with no files
  autocmd StdinReadPre * let s:std_in=1
  autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif

  " Open NERDTree when opening a directory, but focus on it
  autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
augroup END

" Smart relative line number toggle
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

" Auto-reload config on save
augroup config_reload
  autocmd!
  autocmd BufWritePost ~/.config/nvim/init.vim source ~/.config/nvim/init.vim | echo "Config auto-reloaded!"
augroup END

" Highlight the symbol and its references when holding the cursor (CoC)
autocmd CursorHold * silent call CocActionAsync('highlight')

" Go formatting and import management on save
augroup go_format
  autocmd!
  autocmd BufWritePost *.go call GoFormat()
augroup END

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


" Auto-fold imports on file open and save
augroup auto_fold_imports
  autocmd!
  autocmd BufReadPost,BufWritePost *.go,*.ts,*.tsx,*.js,*.jsx,*.rb,*.py call FoldImports()
augroup END