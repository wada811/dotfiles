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

reset="%{$reset_color%}"

bStyle="%(?.%{${fg[white]}%}.%{${fg[red]}%})"
uStyle="%{${fg[cyan]}%}"
aStyle="%(?.%{${fg[white]}%}.%{${fg[red]}%})"
hStyle="%{${fg[cyan]}%}"
cStyle="%(?.%{${fg[white]}%}.%{${fg[red]}%})"
dStyle="%{${fg[cyan]}%}"

rStyle="%{${fg[red]}%}"

bra=${bStyle}[${reset}
ket=${bStyle}]${reset}
user=${uStyle}%n${reset}
at=${aStyle}@${reset}
host=${hStyle}%m${reset}
colon=${cStyle}:${reset}
dir=${dStyle}%c${reset}

PROMPT="${bra}${user}${at}${host}${colon}${dir}${ket}%% " # "[user@host:dirname]% "
PROMPT2="${bra}${user}${at}${host}${colon}${dir}${ket}> " # "[user@host:dirname]> "
SPROMPT="[Yes(y),No(n),Abort(a),Edit(e)]${rStyle}%r${reset} ?"