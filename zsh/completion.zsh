##################
# zsh completion #
##################

# 補完機能を設定する
fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(~/zsh/git-completion $fpath)

# 補完機能を有効にする
autoload -Uz compinit
compinit -u

