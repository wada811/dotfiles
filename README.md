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

    sudo sh -c "echo /usr/local/bin/zsh >> /etc/shells"
    chsh -s /usr/local/bin/zsh