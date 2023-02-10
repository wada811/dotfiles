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
alias ll="ls -lh"
alias la="ll -a"

alias du="du -h"
alias df="df -h"

# Move ~/.Trash instead of removing file
alias rm='(){mv -f $@ ~/.Trash/ }'

alias git="drop_git"

# グローバルエイリアス
alias -g F='$(peco-git-changed-files)'
alias -g H='$(peco-git-hash)'
alias -g B='$(peco-git-branch)'
