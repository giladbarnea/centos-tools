export COLORTERM=truecolor
export TERM=xterm-256color
# export DISPLAY=:0
HISTCONTROL=ignoreboth
ISTIO_PATH=/opt/istio-1.6.7
if [ -e "$ISTIO_PATH" ]; then
  PATH=$ISTIO_PATH/bin:$PATH
  source $ISTIO_PATH/tools/istioctl.bash  # is there .zsh?
fi
[[ -f "/root/.local/share/lscolors.sh" ]] && source "/root/.local/share/lscolors.sh"

if type micro &>/dev/null; then
	export EDITOR=micro
fi

unalias ls 2>/dev/null
function ls(){
  local dest="${1:-$PWD}"
  /bin/ls --group-directories-first -Fagh --color=auto -v "$dest"
  printf "%b\n" "\x1b[1;97m$dest\x1b[0m"
}
function cd() { builtin cd "$@" && ls ; }
function ksm() { kubectl -n secure-management "$@" ; }
function k.pods.names(){
  ksm get pods --no-headers "$@" | cut -d ' ' -f 1
  return $?
}
function k.logs(){
  ksm logs -l app="$1" -c "$1" -f
  return $?
}
function k.nodeofpod(){
  ksm get pods -o wide -l app="$1" | grep "$1" | grep -E -o 'k8s-n-[0-9]+'
}
function k.asmver(){
  ksm get pods -l app="$1" -o yaml | grep -o -m1 -E "image: .*$1:(.+)"
}
function k.exec-bash(){
  local podname="$1"
  shift
  ksm exec -it "$podname" -- bash "$@"
}


# kubectl -n secure-management delete pods rsevents-66468bd865-4jpqv
# kubectl -n secure-management scale deployment --replicas=0 rsevents

# publish / consume a kafka message:
#  exec -ti into kafka
#  unset JMX_PORT
#  kafka-console-producer.sh --broker-list localhost:9092 --topic as-rsevents-mock-consume-topic
# >{"device_event_blocked_traffic":{"message":{"timestamp":"2021-08-23T15:53:00Z","trace_id":"trace_id"}}}
#
#  kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic as-rsevents-mock-consume-topic --from-beginning

# ** Dashboard
# cat dashboard_token dashboard_url


if [[ "${SHELL##*/}" == zsh && -n "$ZSH_VERSION" ]]; then
  export ZSH=${ZSH:-$HOME/.oh-my-zsh}
  source <(kubectl completion zsh)
  if [[ -d $ZSH ]]; then
    # See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
    # refined, josh, fino-time
    ZSH_THEME="fino-time"

    plugins=(zsh-autosuggestions copybuffer sudo extract kubectl colored-man-pages fast-syntax-highlighting)

    source $ZSH/oh-my-zsh.sh

    # bindkey -M emacs "^ "  _expand_alias
  else
    echo "[WARN] ZSH Does not exist: $ZSH" 1>&2
  fi
else
  source <(kubectl completion bash)
  export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

complete -F __start_kubectl k
complete -F __start_kubectl ksm
