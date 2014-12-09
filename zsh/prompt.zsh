##############
# zsh prompt #
##############
#
# zsh: 13. Prompt Expansion
# http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Prompt-Expansion
#
# zsh: 26. User Contributions
# http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#index-colors
#

# How to change Hostname in Mac OS X
# sudo scutil --set HostName [NewHostName]

setopt correct

autoload colors
colors # black, red, green, yellow, blue, magenta, cyan, and white

reset=$reset_color

uStyle=${fg[cyan]}
aStyle=${fg[white]}
hStyle=${fg[cyan]}
cStyle=${fg[white]}
dStyle=${fg[cyan]}

rStyle=${fg[red]}

user=${uStyle}%n${reset}
at=${aStyle}@${reset}
host=${hStyle}%m${reset}
colon=${cStyle}:${reset}
dir=${dStyle}%c${reset}

PROMPT="[${user}${at}${host}${colon}${dir}]%% " # "[user@host:dirname]% "
PROMPT2="[${user}${at}${host}${colon}${dir}]> " # "[user@host:dirname]> "
SPROMPT="[Yes(y),No(n),Abort(a),Edit(e)]${rStyle}%r${reset} ?"