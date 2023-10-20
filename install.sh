#!/bin/bash

brew install git
brew install node
brew install go
brew install java
brew install python
brew install awscli
# List of files to create symlinks for
files=(".vimrc" ".vimrccomplete" ".zprofile" ".zshrc", ".skhdrc")

# Loop through the list of files and create symlinks in the home directory
for file in "${files[@]}"; do
  source_file="$(pwd)/$file"  # Assuming the script is in the same directory as the files
  target_file="$HOME/$file"
  
  # Check if the source file exists
  if [ -f "$source_file" ]; then
    # Create a symbolic link if the source file exists
    ln -s "$source_file" "$target_file"
    echo "Created a symlink for $file in $HOME"
  else
    echo "Source file $file does not exist. Symlink not created."
  fi
done

# Define the list of casks to install
casks=(
  "google-chrome",
  "firefox",
  "cron",
  "zoom",
  "slack",
  "1password",
  "authy",
  "raycast",
  "spectacle",
  "visual-studio-code",
  "postman",
  "spotify"
)

# Install the specified casks
for cask in "${casks[@]}"; do
  brew install --cask "$cask"
done

brew install koekeishiya/formulae/skhd
brew services start skhd

defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
