function peco-git-branch(){
    git branch --sort=-authordate | peco | sed -e "s/^\*[ ]*//g"
}