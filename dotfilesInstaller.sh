#! /bin/bash

ln -s ~/dotfiles/Brewfile ~/Brewfile

ln -s ~/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/dotfiles/.gitignore ~/.gitignore

test -e ~/Library/Preferences/com.googlecode.iterm2.plist && rm ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s ~/dotfiles/.iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s ~/dotfiles/.iterm2/ ~/.iterm2

ln -s ~/dotfiles/.zsh/ ~/.zsh
ln -s ~/dotfiles/.zshrc ~/.zshrc

ln -s ~/dotfiles/.vim/ ~/.vim
ln -s ~/dotfiles/.vimrc ~/.vimrc

ln -s ~/dotfiles/bin/ ~/bin

ln -s ~/dotfiles/.sqliterc ~/.sqliterc
