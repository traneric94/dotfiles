" Modular Neovim Configuration
" ==============================

" Load vim configurations
source ~/.config/nvim/vim/settings.vim
source ~/.config/nvim/vim/plugins.vim
source ~/.config/nvim/vim/keymaps.vim
source ~/.config/nvim/vim/autocmds.vim
source ~/.config/nvim/vim/functions.vim

" Load lua configurations
lua require('init')
