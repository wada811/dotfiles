##############
# zsh prompt #
##############
#
# zsh: 13. Prompt Expansion
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Prompt-Expansion
#

# How to change Hostname in Mac OS X
# sudo scutil --set HostName [NewHostName]

PROMPT="[%n@%m:%c]%% " # "[user@host:dirname]% "
PROMPT2="[%n@%m:%c]> " # "[user@host:dirname]> "
SPROMPT="%r is correct? [n,y,a,e]: "