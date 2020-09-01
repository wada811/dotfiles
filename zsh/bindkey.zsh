###############
# zsh bindkey #
###############

# 履歴から cd
bindkey '^@' peco-cdr

# 履歴からコマンド選択
bindkey '^r' peco-select-history

# 一覧からファイルを選択
bindkey '^f' peco-select-file

# PR 一覧から checkout
bindkey '^g^p' peco-gh-pr-checkout