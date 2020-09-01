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

# 色設定を読み込む
source ~/.zsh/color.zsh
# プロンプト設定を読み込む
source ~/.zsh/prompt.zsh
# タイトル設定を読み込む
source ~/.zsh/title.zsh
# cd設定を読み込む
source ~/.zsh/cd.zsh
# zmv設定を読み込む
source ~/.zsh/zmv.zsh
# ヒストリ設定を読み込む
source ~/.zsh/history.zsh
# キーバインド設定を読み込む
source ~/.zsh/bindkey.zsh
# オプション設定を読み込む
source ~/.zsh/options.zsh
# エイリアス設定を読み込む
source ~/.zsh/alias.zsh

# zsh-notify を有効にする (require add-zsh-hook)
source ~/.zsh/zsh-notify/notify.plugin.zsh

# load peco scripts (require cdr)
for f (~/.zsh/peco-scripts/*) source "${f}"
# load zsh functions
for f (~/.zsh/zsh-functions/*) source "${f}"
# hook設定を読み込む
source ~/.zsh/hook.zsh

# direnv
eval "$(direnv hook zsh)"

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"
eval "$(direnv hook zsh)"
export PATH="$HOME/.yarn/bin:$PATH"

# パス
export JAVA_HOME=`/usr/libexec/java_home`
export ANDROID_AVD_HOME=~/.android/avd
export ANDROID_HOME=~/Library/Android/sdk

ANDROID_LATEST_BUILD_TOOLS=$(ls -r $ANDROID_HOME/build-tools | head -1 | tr -d '/')
export PATH=~/bin:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/$ANDROID_LATEST_BUILD_TOOLS:/usr/local/bin:/usr/local/share:$PATH


# export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
