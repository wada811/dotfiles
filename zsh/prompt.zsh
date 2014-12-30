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

mark="%(?.%{${fg[white]}%}.%{${fg[red]}%})"
text="%{${fg[cyan]}%}"

notice="%{${fg[red]}%}"

bra="${mark}[${reset}"
ket="${mark}]${reset}"
user="${text}%n${reset}"
at="${mark}@${reset}"
host="${text}%m${reset}"
colon="${mark}:${reset}"
dir="${text}%c${reset}"

PROMPT="${bra}${user}${at}${host}${colon}${dir}${ket}%% " # "[user@host:dirname]% "
PROMPT2="${bra}${user}${at}${host}${colon}${dir}${ket}> " # "[user@host:dirname]> "
SPROMPT="[Yes(y),No(n),Abort(a),Edit(e)]${notice}%r${reset} ?"

unset reset
unset mark
unset text
unset notice
unset bra
unset ket
unset user
unset at
unset host
unset colon
unset dir