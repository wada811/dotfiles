function peco-select-file() {
    LBUFFER+=$(\find . | \peco)
    CURSOR=$#LBUFFER
}
zle -N peco-select-file