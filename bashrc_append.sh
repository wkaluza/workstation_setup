shopt -s histappend
shopt -s cmdhist
HISTFILESIZE=1000000
HISTSIZE=1000000
# HISTIGNORE='pwd:top:ps'
HISTCONTROL=ignorespace:erasedups
PROMPT_COMMAND='history -n ; history -a'
alias python=python3
PATH="$PATH":"/usr/local/go/bin"
PATH="$PATH":"${HOME}/.local/bin"
