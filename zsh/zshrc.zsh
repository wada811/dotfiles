#####################
# ~/.zshrc template #
#####################

# 環境変数LANG
export LANG=ja_JP.UTF-8
# Emacs キーバインド
bindkey -e
# 補完機能を有効にする
autoload -Uz compinit
compinit -u

# 色設定を読み込む
source ~/dotfiles/zsh/color.zsh
# プロンプト設定を読み込む
source ~/dotfiles/zsh/prompt.zsh
# タイトル設定を読み込む
source ~/dotfiles/zsh/title.zsh
# cd設定を読み込む
source ~/dotfiles/zsh/cd.zsh
# ヒストリ設定を読み込む
source ~/dotfiles/zsh/history.zsh

# エイリアス設定を読み込む
source ~/dotfiles/zsh/alias.zsh