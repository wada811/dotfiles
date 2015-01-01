#
# zshでEnterを連打したときにいろいろ実行する - Qiita
# http://qiita.com/znz/items/559721cbf238d77de6bb
#

function do_enter() {
    if [ -n "$BUFFER" ]; then
        zle accept-line
        return 0
    fi
    if [ "$WIDGET" != "$LASTWIDGET" ]; then
        MY_ENTER_COUNT=0
    fi
    case $[MY_ENTER_COUNT++] in
        0)
            BUFFER=" ls_abbrev"
            ;;
        1)
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                BUFFER=" git status -sb"
            fi
            ;;
        *)
            unset MY_ENTER_COUNT
            ;;
    esac
    builtin zle .accept-line
    return 0
}
zle -N do_enter
bindkey '^m' do_enter