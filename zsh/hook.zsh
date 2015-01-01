############
# zsh hook #
############
#
# zshでhook関数を登録する - Qiita
# http://qiita.com/mollifier/items/558712f1a93ee07e22e2
#

# カレントディレクトリが変更したとき
chpwd() {
    ls_abbrev
}
