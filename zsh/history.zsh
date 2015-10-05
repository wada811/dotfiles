###############
# zsh history #
###############

# 履歴設定
## ヒストリを保存するファイル
HISTFILE=~/.zsh_history
## メモリ上のヒストリ数
HISTSIZE=1000000
## 保存するヒストリ数
SAVEHIST=$HISTSIZE

## ヒストリファイルにコマンドだけではなく実行時刻と実行時間も保存する
setopt extended_history
## 同じコマンドを連続で実行した場合はヒストリに登録しない
setopt hist_ignore_dups
## スペースで始まるコマンドはヒストリに登録しない
setopt hist_ignore_space
## すぐにヒストリに登録する
setopt inc_append_history
## zsh プロセス間でヒストリを共有する
setopt share_history

# 履歴からコマンド補完
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end