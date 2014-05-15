# [wada811's dotfiles](http://wada811.blogspot.com/2014/05/dotfiles.html)

## Install dotfiles
    cd ~
    git clone https://github.com/wada811/dotfiles.git

## Show dotfiles

    defaults write com.apple.finder AppleShowAllFiles -boolean true && killall Finder

## Usage dotfilesInstaller.sh

    cd ~/dotfiles
    ./dotfilesInstaller.sh

## [Install Homebrew](http://brew.sh/#install)

    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

## [Install Formulas and Applications via Homebrew and Homebrew-cask](http://wada811.blogspot.com/2014/05/brewfile-homebrew-cask.html)

    cd ~
    brew bundle

##  Change default shell to Zsh

    sudo sh -c "echo '/usr/local/bin/zsh' >> /etc/shells"
    chsh -s /usr/local/bin/zsh

## Symlink .ssh

    ln -s ~/Dropbox/dotfiles/.netrc ~/.netrc
    ln -s ~/Dropbox/dotfiles/.ssh/id_rsa ~/.ssh/id_rsa
    ln -s ~/Dropbox/dotfiles/.ssh/id_rsa.pub ~/.ssh/id_rsa.pub
    ssh-add ~/.ssh/id_rsa

## Symlink diff-highlight

    ln -s /usr/local/opt/git/share/git-core/contrib/diff-highlight/diff-highlight /usr/local/bin

## [Symlink Sublime Text 2](http://wada811.blogspot.com/2013/01/sharing-sublime-text-2-settings-with-dropbox.html)

    rm -rf ~/Library/Application\ Support/Sublime\ Text\ 2/
    ln -s ~/Dropbox/Settings/Sublime\ Text\ 2/ ~/Library/Application\ Support/Sublime\ Text\ 2
