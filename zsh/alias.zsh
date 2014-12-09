#############
# zsh alias #
#############

# aliased ls needs if file/dir completions work
setopt complete_aliases

# -G Enable colorized output.
# -F Display marks.
# -l long listing
# -a list entries starting with .
alias ls="ls -GF"
alias ll="ls -l"
alias la="ll -a"

alias du="du -h"
alias df="df -h"