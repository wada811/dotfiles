# Update Homebrew
update || true

# Upgrate Formulas
upgrade || true

# Install HomebrewCask
tap caskroom/cask || true
install brew-cask || true

####################
# Install Packages #
####################

## Shell
install zsh || true
install zsh-completions || true
install terminal-notifier || true

## Git
install git || true
install hub || true

## Android
install android-sdk
install android-ndk

## Required
install readline || true
install openssl || true

## Ruby
install rbenv || true
install ruby-build || true

## SQL
install mysql || true
install sqlite || true

## Utils
install tree || true
install jq || true
install rename || true
install figlet || true

## Image and Video
install imagemagick || true
install ffmpeg || true

########################
# Install Applications #
########################

## Browser
cask install google-chrome || true
cask install firefox || true

## Editor
cask install sublime-text || true
cask install coteditor || true

## IDE
cask install java || true
cask install eclipse-ide || true
cask install android-studio || true

## Utils
cask install google-japanese-ime || true
cask install dropbox || true
cask install cyberduck || true
cask install the-unarchiver || true
cask install appcleaner || true

# Remove outdated versions
cleanup
cask cleanup