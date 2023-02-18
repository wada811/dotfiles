# [wada811's dotfiles](http://wada811.blogspot.com/2014/05/dotfiles.html)

## Install dotfiles
    git clone https://github.com/wada811/dotfiles.git

## Usage install.sh

    ./install.sh

## Show dotfiles

    defaults write com.apple.finder AppleShowAllFiles -boolean true && killall Finder

## Install Rosetta

    sudo softwareupdate --install-rosetta --agree-to-license

## [Install Homebrew](http://brew.sh/#install)

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


## [Install Formulas and Applications via Homebrew and Homebrew-cask](http://wada811.blogspot.com/2014/05/brewfile-homebrew-cask.html)

    brew-update

## Symlink diff-highlight

    ln -s /opt/homebrew/opt/git/share/git-core/contrib/diff-highlight/diff-highlight /usr/local/bin
