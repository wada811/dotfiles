# wada811's dotfiles

## Install dotfiles
    cd ~
    git clone https://github.com/wada811/dotfiles.git

## Usage dotfilesInstaller.sh

    cd ~/dotfiles
    chmod +x dotfilesInstaller.sh
    ./dotfilesInstaller.sh

## [Install HomeBrew](http://brew.sh/#install)

    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

## Install Formulas and Applications via HomeBrew and HomeBrew-cask

    cd ~
    brew bundle

##  Change default shell to Zsh

    sudo sh -c "echo '/usr/local/bin/zsh' >> /etc/shells"
    chsh -s /usr/local/bin/zsh

## Symlink diff-highlight

    ln -s /usr/local/opt/git/share/git-core/contrib/diff-highlight/diff-highlight /usr/local/bin

## Show dotfiles

    defaults write com.apple.finder AppleShowAllFiles -boolean true && killall Finder
