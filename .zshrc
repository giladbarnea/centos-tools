# https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/
# xclip: https://centos.pkgs.org/7/epel-aarch64/xclip-0.12-5.el7.aarch64.rpm.html
#        https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/x/xclip-0.12-5.el7.x86_64.rpm
# xsel: https://centos.pkgs.org/7/epel-aarch64/xsel-1.2.0-15.el7.aarch64.rpm.html

export COLORTERM=truecolor
export TERM=xterm-256color
# export DISPLAY=:0
HISTCONTROL=ignoreboth
if [ -e "/opt/istio-1.6.7" ]; then
  export ISTIO_PATH=/opt/istio-1.6.7
  export PATH="$ISTIO_PATH/bin:$PATH"
  source "$ISTIO_PATH"/tools/istioctl.bash  # is there .zsh?
fi
[[ -f "/root/.local/share/lscolors.sh" ]] && source "/root/.local/share/lscolors.sh"

if type micro &>/dev/null; then
	export EDITOR=micro
fi

unalias ls 2>/dev/null
function ls(){
  printf "%b" "ls $*"
  # shellcheck disable=SC2124
  local dest="${@:(-1)}"
  if [[ -z "$dest" || ! -d "$dest" ]]; then
    dest="$PWD"
  fi
  /usr/bin/ls --group-directories-first -Fagh --color=auto -v "$dest"
  printf "\n%b\n" "\x1b[1;97m$dest\x1b[0m"
}
function cd() { builtin cd "$@" && ls ; }
alias ksm="kubectl --namespace=secure-management"
# function ksm() { kubectl -n secure-management "$@" ; }
function k.pods.names(){
  log.debug "ksm get pods --no-headers $* | cut -d ' ' -f 1"
  ksm get pods --no-headers "$@" | cut -d ' ' -f 1
  return $?
}
function k.logs(){
  local app="$1"
  shift || return 1
  log.debug "ksm logs -l app=$app -f"
  ksm logs -l app="$app" -f
  return $?
}
function k.nodeofpod(){
  local app="$1"
  shift || return 1
  log.debug "ksm get pods -o wide -l app=$app | grep $app | grep -E -o 'k8s-n-[0-9]+'"
  ksm get pods -o wide -l app="$app" | grep "$app" | grep -E -o 'k8s-n-[0-9]+'
}
function k.asmver(){
  # ksm get asm-version -o jsonpath='{.items[0].metadata.name}'
  local app="$1"
  shift || return 1
  log.debug "ksm get pods -l app=$app -o yaml | grep -o -m1 -E \"image: .*$app:(.+)\""
  ksm get pods -l app="$app" -o yaml | grep -o -m1 -E "image: .*$app:(.+)"
}
function k.exec-bash(){
  local pod="$1"
  shift || return 1
  log.debug "ksm exec -it $pod -- bash \"$*\""
  ksm exec -it "$pod" -- bash "$@"
}


# kubectl -n secure-management delete pods rsevents-66468bd865-4jpqv
# kubectl -n secure-management scale deployment --replicas=0 rsevents

# ======[ Kafka ]======
# ========================================
#  exec -ti into kafka
#  unset JMX_PORT
#
# -----[ General ]-----
# List topics: kafka-topics.sh --list --zookeeper zookeeper:2181
# -----[ Publish ]-----
#  kafka-console-producer.sh --broker-list localhost:9092 --topic as-rsevents-mock-consume-topic
# >{"device_event_blocked_traffic":{"message":{"timestamp":"2021-08-23T15:53:00Z","trace_id":"trace_id"}}}
#
# -----[ Consume ]-----
# kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic as-rsevents-mock-consume-topic --from-beginning
# kafka-console-consumer.sh --bootstrap-server kafka-0:9092 --topic ...
# kafka-console-consumer.sh --bootstrap-server kafka-0:9092 --whitelist 'as-rs.*|as-rsevents.*|hs-routers.*|as-hs.*'

# -----[ Certs ]-----
# kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data['ca\.crt']}" | base64 --decode
# kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data['client\.key']}" | base64 --decode
# kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data['client\.crt']}" | base64 --decode

# -----[ Dashboard ]-----
# cat dashboard_token dashboard_url


if [[ -n "$ZSH_VERSION" ]]; then
  if [[ "${SHELL##*/}" == zsh ]]; then
    if { [[ -z "$ZSH" || ! -d "$ZSH" ]] && [[ -d "$HOME/.oh-my-zsh" ]] ; }; then
      # ZSH var is not set, or $ZSH is not a directory, but "$HOME/.oh-my-zsh" is a directory
      export ZSH="$HOME/.oh-my-zsh"
    fi
    if [[ -d "$ZSH" ]]; then
      # See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
      # refined, josh, fino-time
      ZSH_THEME="fino-time"

      plugins=()
      if [[ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]]; then
        plugins+=(zsh-autosuggestions)
      fi
      plugins+=(copybuffer sudo extract kubectl colored-man-pages docker-compose)
      if [[ -d "$ZSH/custom/plugins/fast-syntax-highlighting" ]]; then
        plugins+=(fast-syntax-highlighting)
      fi

      source "$ZSH"/oh-my-zsh.sh

      setopt extendedglob
      setopt auto_menu
      bindkey -M emacs "^ "  _expand_alias
    else
      echo "[WARN] \$ZSH Does not exist: $ZSH" 1>&2
      if type complete &>/dev/null; then
        source <(kubectl completion zsh)
      fi
    fi
  fi
else # not ZSH_VERSION
  if type complete &>/dev/null; then
    source <(kubectl completion bash)
    # if [[ -f /root/ksm-completion-bash ]]; then
    #   source /root/ksm-completion-bash
    # fi
    # if [[ -f /root/k-completion-bash ]]; then
    #   source /root/k-completion-bash
    # fi
  fi
  export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi


{ ! type isdefined \
  && source <(wget -qO- https://raw.githubusercontent.com/giladbarnea/bashscripts/master/util.sh) ;
} &>/dev/null