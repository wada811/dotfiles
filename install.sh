#! /bin/bash

ln -s ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/dotfiles/git/.gitattributes ~/.gitattributes
ln -s ~/dotfiles/git/.gitignore ~/.gitignore

test -e ~/Library/Preferences/com.googlecode.iterm2.plist && rm ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s ~/dotfiles/.iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s ~/dotfiles/.iterm2/ ~/.iterm2

ln -s ~/dotfiles/zsh/ ~/.zsh
ln -s ~/dotfiles/zsh/zshrc.zsh ~/.zshrc
touch ~/dotfiles/zsh/zprofile.zsh
ln -s ~/dotfiles/zsh/zprofile.zsh ~/.zprofile

ln -s ~/dotfiles/.vim/ ~/.vim
ln -s ~/dotfiles/.vimrc ~/.vimrc

ln -s ~/dotfiles/bin/ ~/bin

ln -s ~/dotfiles/.sqliterc ~/.sqliterc