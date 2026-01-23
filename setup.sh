#!/bin/bash
#
# bootstrap script for installing dotfiles
#
# usage:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/a160v/dotfiles/master/setup.sh)"
#

set -e

DOTFILES_REPO="git@github.com:a160v/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

echo "-----> Bootstrap dotfiles..."

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Please try again after Xcode Command Line Tools are installed."
  exit 1
fi

# Clone repository if needed
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "-----> Cloning dotfiles repository..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  echo "-----> Dotfiles directory already exists. Pulling latest changes..."
  cd "$DOTFILES_DIR"
  git pull origin master
fi

# Run install script
cd "$DOTFILES_DIR"
chmod +x install.sh
./install.sh

echo "-----> Bootstrap complete!"
