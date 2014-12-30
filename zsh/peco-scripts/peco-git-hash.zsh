function peco-git-hash(){
    git lg | peco | sed -e "s/^[\*\|][ |\\\/\*]*//g" | awk '{ print $1 }'
}