############
# zsh hook #
############
#
# zshでhook関数を登録する - Qiita
# http://qiita.com/mollifier/items/558712f1a93ee07e22e2
#

# カレントディレクトリが変更したとき（対話シェルのみ。エージェント用の非対話シェルには付けない）
if [[ -o interactive ]]; then
    chpwd() {
        ls_abbrev
    }
fi
