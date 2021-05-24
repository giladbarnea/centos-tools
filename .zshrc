# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
if [[ ! -d $ZSH ]]; then
	echo "Does not exist: $ZSH"
	return 1
fi
export COLORTERM=truecolor
export TERM=xterm-256color

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# refined, josh, fino-time
ZSH_THEME="fino-time"
HISTCONTROL=ignoreboth

# export DISPLAY=:0
plugins=(zsh-autosuggestions fast-syntax-highlighting kubectl colored-man-pages)

source $ZSH/oh-my-zsh.sh
export COLORTERM=truecolor
export TERM=xterm-256color

# bindkey -M emacs "^ "  _expand_alias
if type micro &>/dev/null; then
	export EDITOR=micro
fi
# User configuration
function cd() { builtin cd "$@" && /usr/bin/ls --group-directories-first -Flaght --color=auto && echo "$PWD"; }
alias ls='/usr/bin/ls --group-directories-first -Flaght --color=auto'

alias ksm='k -n secure-management'

# source <(kubectl completion bash)
# complete -F __start_kubectl k
# ISTIO_PATH=/opt/istio-1.6.7
# PATH=$ISTIO_PATH/bin:$PATH
# source $ISTIO_PATH/tools/istioctl.bash
