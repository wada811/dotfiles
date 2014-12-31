#####################
# ~/.zshrc template #
#####################

# 環境変数LANG
export LANG=ja_JP.UTF-8
# Emacs キーバインド
bindkey -e

# 補完機能を有効にする
source ~/.zsh/completion.zsh

# add-zsh-hook を有効にする
autoload -Uz add-zsh-hook

# zsh-notify を有効にする (require add-zsh-hook)
source ~/.zsh/zsh-notify/notify.plugin.zsh

# no remove postfix slash of command line
setopt noautoremoveslash

# 色設定を読み込む
source ~/.zsh/color.zsh
# プロンプト設定を読み込む
source ~/.zsh/prompt.zsh
# タイトル設定を読み込む
source ~/.zsh/title.zsh
# cd設定を読み込む
source ~/.zsh/cd.zsh
# ヒストリ設定を読み込む
source ~/.zsh/history.zsh

# load peco scripts (require cdr)
for f (~/.zsh/peco-scripts/*) source "${f}"

# エイリアス設定を読み込む
source ~/.zsh/alias.zsh

# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# フローコントロールを無効にする
setopt no_flow_control

# '#' 以降をコメントとして扱う
setopt interactive_comments

# パス
export JAVA_HOME=`/usr/libexec/java_home`
export ANDROID_SDK_HOME=/usr/local/opt/android-sdk
export ANDROID_NDK_HOME=/usr/local/opt/android-ndk
PATH=~/bin:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_NDK_HOME:/usr/local/bin:/usr/local/share:$PATH
export PATH

