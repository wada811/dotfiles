# シンプルな zshrc

# zsh補完を有効化
fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(~/.zsh/completion $fpath)

# 補完機能を有効にする
autoload -Uz compinit
compinit -u

# add-zsh-hook を有効にする | zsh-notify を有効にする
autoload -Uz add-zsh-hook
source ~/.zsh/zsh-notify/notify.plugin.zsh

# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups


# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000


# emacs 風キーバインドにする
bindkey -e

# その他とりあえずいるもの
export LANG=ja_JP.UTF-8

# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# フローコントロールを無効にする
setopt no_flow_control

# '#' 以降をコメントとして扱う
setopt interactive_comments

# 履歴からコマンド補完
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end

# パス
export ANDROID_SDK_HOME=/usr/local/opt/android-sdk
export ANDROID_NDK_HOME=/usr/local/opt/android-ndk
PATH=~/bin:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_NDK_HOME:/usr/local/bin:/usr/local/share:$PATH
export PATH

# ソフトウェアエイリアス
alias st="/Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl"

# rbenv の初期化
eval "$(rbenv init -)"
