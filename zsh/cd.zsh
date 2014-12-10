##########
# zsh cd #
##########
#
# zsh: 16. Options
# 16.2.1 Changing Directories
# http://zsh.sourceforge.net/Doc/Release/Options.html#Changing-Directories
#

# auto change directory
setopt auto_cd

# Make cd push the old directory onto the directory stack.
setopt auto_pushd

# Don't push multiple copies of the same directory onto the directory stack.
setopt pushd_ignore_dups