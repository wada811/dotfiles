# Update Homebrew
update

# Upgrade Formulas
upgrade

# Install HomebrewCask
tap caskroom/cask
tap caskroom/versions
install caskroom/cask/brew-cask

####################
# Install Packages #
####################

## Font
tap sanemat/font
install sanemat/font/ricty

## Shell
install zsh
install zsh-completions
install terminal-notifier

## Git
install git
install hub

## Android
install android-sdk
install android-ndk || (brew unlink android-ndk && brew install android-ndk)

## Required
install readline
install openssl

## Ruby
install rbenv
install ruby-build

## SQL
install mysql
install sqlite

## Utils
install tree
install jq
install rename
install figlet

## Image and Video
install imagemagick
install ffmpeg

########################
# Install Applications #
########################

## Browser
cask install --appdir=/Applications google-chrome
cask install --appdir=/Applications firefox

## Editor
cask install --appdir=/Applications sublime-text3
cask install --appdir=/Applications coteditor

## IDE
# JDK6/JDK7 for Android Studio
cask install --appdir=/Applications java
cask install --appdir=/Applications java7
cask install --appdir=/Applications java6
cask install --appdir=/Applications eclipse-ide
cask install --appdir=/Applications android-studio

## Utils
cask install --appdir=/Applications google-japanese-ime
cask install --appdir=/Applications dropbox
cask install --appdir=/Applications cyberduck
cask install --appdir=/Applications the-unarchiver
cask install --appdir=/Applications appcleaner
cask install --appdir=/Applications openoffice
cask install --appdir=/Applications gyazo
cask install --appdir=/Applications gimp
cask install --appdir=/Applications imageoptim

# Remove outdated versions
cleanup
cask cleanup
