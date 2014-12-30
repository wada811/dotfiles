function peco-git-branch(){
    git branch | peco | sed -e "s/^\*[ ]*//g"
}