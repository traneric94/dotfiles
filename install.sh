#!/bin/bash

# List of files to create symlinks for
files=(".vimrc" ".vimrccomplete" ".zprofile" ".zshrc")

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

