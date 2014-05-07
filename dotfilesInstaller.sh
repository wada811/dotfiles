#! /bin/bash
ln -s ~/dotfiles/Brewfile ~/Brewfile
ln -s ~/dotfiles/Settings.terminal ~/Settings.terminal
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/dotfiles/.gitignore ~/.gitignore
ln -s ~/dotfiles/.sqliterc ~/.sqliterc
if [ ! -d ~/.vim ]; then ln -s ~/dotfiles/.vim ~/.vim > /dev/null 2>&1; fi
ln -s ~/dotfiles/.vimrc ~/.vimrc
if [ ! -d ~/.zsh ]; then ln -s ~/dotfiles/.zsh ~/.zsh > /dev/null 2>&1; fi
ln -s ~/dotfiles/.zshrc ~/.zshrc