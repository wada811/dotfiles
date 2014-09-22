#! /bin/bash

ln -s ~/dotfiles/Brewfile ~/Brewfile

ln -s ~/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/dotfiles/.gitignore ~/.gitignore

rm ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s ~/dotfiles/.iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s ~/dotfiles/.iterm2/ ~/.iterm2

ln -s ~/dotfiles/.zsh/ ~/.zsh
ln -s ~/dotfiles/.zshrc ~/.zshrc

ln -s ~/dotfiles/.vim/ ~/.vim
ln -s ~/dotfiles/.vimrc ~/.vimrc

    # ln -s ~/dotfiles/adb-peco/bin/adb_peco.sh ~/dotfiles/bin/adb_peco.sh
    # ln -s ~/dotfiles/adb-peco/bin/adbp ~/dotfiles/bin/adbp
    # ln -s ~/dotfiles/adb-peco/bin/pidcatp ~/dotfiles/bin/pidcatp

    # ln -s ~/dotfiles/ADB-Tools/bin/adb-screencap ~/dotfiles/bin/adb-screencap
    # ln -s ~/dotfiles/ADB-Tools/bin/adb-screenrecord ~/dotfiles/bin/adb-screenrecord

ln -s ~/dotfiles/bin/ ~/bin

ln -s ~/dotfiles/.sqliterc ~/.sqliterc
