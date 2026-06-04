# パス
export JAVA_HOME=/Applications/"Android Studio.app"/Contents/jbr/Contents/Home
export ANDROID_AVD_HOME=~/.android/avd
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_SDK_ROOT=~/Library/Android/sdk

# マシン固有の環境変数（gitignore 済み）
[ -f ~/.zsh/zprofile.zsh ] && source ~/.zsh/zprofile.zsh

# Android SDK 未インストール時はディレクトリが無いので stderr を抑制（空になり path からは除外される）
ANDROID_LATEST_BUILD_TOOLS=$(ls -r $ANDROID_HOME/build-tools 2>/dev/null | head -1 | tr -d '/')

typeset -gU path PATH
path=(
    ~/.local/bin(N-/)
    ~/bin(N-/)
    $ANDROID_HOME/emulator(N-/)
    $ANDROID_HOME/platform-tools(N-/)
    $ANDROID_HOME/build-tools/$ANDROID_LATEST_BUILD_TOOLS(N-/)
    /usr/local/bin(N-/)
    $PATH
)