# パス
export JAVA_HOME=/Applications/"Android Studio.app"/Contents/jbr/Contents/Home
export ANDROID_AVD_HOME=~/.android/avd
export ANDROID_HOME=~/Library/Android/sdk

ANDROID_LATEST_BUILD_TOOLS=$(ls -r $ANDROID_HOME/build-tools | head -1 | tr -d '/')

typeset -gU path PATH
path=(
    ~/bin(N-/)
    $ANDROID_HOME/tools(N-/)
    $ANDROID_HOME/platform-tools(N-/)
    $ANDROID_HOME/build-tools/$ANDROID_LATEST_BUILD_TOOLS(N-/)
    /usr/local/bin(N-/)
    $PATH
)

eval "$(/opt/homebrew/bin/brew shellenv)"