function peco-git-hash(){
    git log --oneline --branches | peco | awk '{print $1}'
}