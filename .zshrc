# https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/
# xclip: https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/x/xclip-0.12-5.el7.x86_64.rpm

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'


[[ -f "/root/.local/share/lscolors.sh" ]] && source "/root/.local/share/lscolors.sh"

export COLORTERM=truecolor
export TERM=xterm-256color
# export DISPLAY=:0
HISTCONTROL=ignoreboth
export HISTORY_IGNORE="(exit|clear|disown|bg|fg)"

unalias ls 2>/dev/null
function ls(){
  local dest="${1:-$PWD}"
  command ls "$dest" -Faghv --color=auto --group-directories-first "${@:2}" && \
  printf "\n\x1b[1;97m%s\x1b[0m\n\n" "$(realpath "$dest")"
}
function cd() { builtin cd "$@" && ls ; }
alias ksm="k -n secure-management"
# function ksm() { kubectl -n secure-management "$@" ; }
function k.pods.names(){
  log.debug "kubectl -n secure-management get pods --no-headers $* | cut -d ' ' -f 1"
  kubectl -n secure-management get pods --no-headers "$@" | cut -d ' ' -f 1
  return $?
}
function k.logs(){
  local app="$1"
  shift || return 1
  log.debug "kubectl -n secure-management logs -l app=$app -f"
  kubectl -n secure-management logs -l app="$app" -f
  return $?
}
function k.nodeofpod(){
  local app="$1"
  shift || return 1
  log.debug "kubectl -n secure-management get pods -o wide -l app=$app | grep $app | grep -E -o 'k8s-n-[0-9]+'"
  kubectl -n secure-management get pods -o wide -l app="$app" | grep "$app" | grep -E -o 'k8s-n-[0-9]+'
}
function k.asmver(){
  # kubectl -n secure-management get asm-version -o jsonpath='{.items[0].metadata.name}'
  local app="$1"
  shift || return 1
  log.debug "kubectl -n secure-management get pods -l app=$app -o yaml | grep -o -m1 -E \"image: .*$app:(.+)\""
  kubectl -n secure-management get pods -l app="$app" -o yaml | grep -o -m1 -E "image: .*$app:(.+)"
}
function k.exec-bash(){
  local pod="$1"
  shift || return 1
  log.debug "kubectl -n secure-management exec -it $pod -- bash \"$*\""
  kubectl -n secure-management exec -it "$pod" -- bash "$@"
}
function k.port-forward(){
  :
#  kubectl -n secure-management port-forward deployment/mongo 28015:27017
#  kubectl -n secure-management port-forward pods/mongo-75f59d57f4-4nd6q 28015:27017
#  kubectl -n secure-management port-forward mongo-75f59d57f4-4nd6q 28015:27017
}

function k.configmap(){
  :
  # mkdir rsevents-perf
  # k create configmap rsevents-perf-cmap --from-file=/root/rsevents-perf   # must abs path

  # spec:
  #   volumes:
  #     - name: rsevents-perf-volume
  #     configMap:
  #       name: rsevents-perf-cmap
  #       # defaultMode: 420
  #   containers:
  #     volumeMounts:
  #       - name: rsevents-perf-volume
  #         mountPath: /app/main/test
  #         readOnly: true
  #         # subPath: sync_handler.py

  # env:
  # - name: RSEVENTS_TESTS_TIMESTAMP
  #   value: '2022-01-02T10:35:05Z'
  # - name: RSEVENTS_TESTS_ACCOUNT_ID
  #   value: GILAD_ACCOUNT_0
  # - name: RSEVENTS_TESTS_DEVICE_ID
  #   value: GILAD_DEVICE_ID_0
  # - name: RSEVENTS_TESTS_ROUTER_ID
  #   value: GILAD_DEVICE_ID_0
  # - name: RSEVENTS_TESTS_USER_ID
  #   value: GILAD_USER_0
  # - name: STATISTICS_INTERVAL_MS
  #   value: '333'
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
      plugins+=(copybuffer extract kubectl colored-man-pages helm)
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
#  if type complete &>/dev/null; then   # i think .bashrc already loads completions
#    source <(kubectl completion bash)
#    # if [[ -f /root/ksm-completion-bash ]]; then
#    #   source /root/ksm-completion-bash
#    # fi
#    # if [[ -f /root/k-completion-bash ]]; then
#    #   source /root/k-completion-bash
#    # fi
#  fi
  export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi
declare istio_path=$(find /opt -maxdepth 1 -type d -name 'istio*')
if [ -e "$istio_path" ]; then
  export ISTIO_PATH="$istio_path"
  export PATH="$ISTIO_PATH/bin:$PATH"
  autoload bashcompinit
  bashcompinit
  source "$ISTIO_PATH"/tools/istioctl.bash 2>/dev/null
fi
if type micro &>/dev/null; then
	export EDITOR=micro
fi

#{ ! type isdefined \
#  && source <(wget -qO- https://raw.githubusercontent.com/giladbarnea/bashscripts/master/util.sh) ;
#} &>/dev/null