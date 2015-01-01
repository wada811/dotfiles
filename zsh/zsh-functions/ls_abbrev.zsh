#
# Zsh - chpwd内のlsでファイル数が多い場合に省略表示する - Qiita
# http://qiita.com/yuyuchu3333/items/b10542db482c3ac8b059
#

function ls_abbrev() {
    if [[ ! -r $PWD ]]; then
        return
    fi
    # -a : Do not ignore entries starting with ..
    # -C : Force multi-column output.
    # -F : Append indicator (one of */=>@|) to entries.
    local cmd_ls='ls'
    local -a opt_ls
    opt_ls=('-aCF' '--color=always')
    case "${OSTYPE}" in
        freebsd*|darwin*)
            if type gls > /dev/null 2>&1; then
                cmd_ls='gls'
            else
                # -G : Enable colorized output.
                opt_ls=('-aCFG')
            fi
            ;;
    esac

    local ls_result
    ls_result=$(CLICOLOR_FORCE=1 COLUMNS=$COLUMNS command $cmd_ls ${opt_ls[@]} | sed $'/^\e\[[0-9;]*m$/d')

    local ls_lines=$(echo "$ls_result" | wc -l | tr -d ' ')

    if [ $ls_lines -gt 2 ]; then
        echo "$ls_result" | head -n 1
        echo '...'
        echo "$ls_result" | tail -n 1
        echo "$(command ls -1 -A | wc -l | tr -d ' ') files exist"
    else
        echo "$ls_result"
    fi
}