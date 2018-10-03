HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

autoload -U compinit promptinit
compinit
promptinit; prompt gentoo

zstyle ':completion::complete:*' use-cache 1

alias public-ip='dig +short myip.opendns.com @resolver1.opendns.com' # Returns public IP
alias ls='ls --color=auto' # color ls output
alias grep='grep --color=auto' # color grep output
alias diff='colordiff' # color diff output
alias ports='netstat -tulanp' # lists open network ports
alias wget='wget -c' # make wget default to continue download on lost connections
alias meminfo='free -m -l -t' # memory and swap information humanreadable output
