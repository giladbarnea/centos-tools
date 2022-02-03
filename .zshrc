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


  # To install:
  # wget http://artifactory.rdlab.local/artifactory/allot-secure-gradle-dev-local/Secure-Management/30.1/30.1.1/30.1.1_1663/Secure-Management-30.1.1.1663.tar
  # extract
  # cd into currently installed version, i.e /opt/ASM1610
  # ./install.sh then choose Uninstall
  # then cd into extracted tar file
  # ./install.sh
}
function k.exec-bash(){
  local pod="$1"
  shift || return 1
  log.debug "kubectl -n secure-management exec -it $pod -- bash \"$*\""
  kubectl -n secure-management exec -it "$pod" -- bash "$@"
}
function k.port-forward(){
  :
  kubectl -n secure-management port-forward deployment/mongo 28015:27017
  kubectl -n secure-management port-forward pods/mongo-75f59d57f4-4nd6q 28015:27017
  kubectl -n secure-management port-forward mongo-75f59d57f4-4nd6q 28015:27017

  # Listen on port 8888 on all addresses, forwarding to 5000 in the pod
  kubectl port-forward --address 0.0.0.0 pod/mypod 8888:5000
}

function k.configmap(){
  :
  # kubectl edit configmap -n <namespace> <configMapName> -o yaml
  # mkdir rs-mult
  # k create configmap rs-mult-cmap --from-file=/root/rs-mult   # must abs path

  # spec:
  #   volumes:
  #     - name: rs-mult-vol-main
  #       configMap:
  #         name: rs-mult-main
  #         defaultMode: 420
  #     - name: rs-mult-vol-test-mocks
  #       configMap:
  #         name: rs-mult-test-mocks
  #         defaultMode: 420
  #     - name: rs-mult-vol-infra-eb-consumers-proto-consumer
  #       configMap:
  #         name: rs-mult-infra-eb-consumers-proto-consumer
  #         defaultMode: 420
  #     - name: rs-mult-vol-infra-eb-consumers-init
  #       configMap:
  #         name: rs-mult-infra-eb-consumers-init
  #         defaultMode: 420
  #   containers:
  #     volumeMounts:
  #       - name: rs-mult-vol-main
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

function rseval(){
  i=0
  for foo in $(kubectl -n secure-management get pods --no-headers | grep rsevents | cut -d ' ' -f 1); do
    eval "rsevents${i}=$foo"
  	echo "rsevents${i}: $foo"
    ((i++))
  done
}

# =========================================
# ===============[ kubectl ]===============
# =========================================
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
# kubectl -n secure-management delete pods rsevents-66468bd865-4jpqv
# kubectl -n secure-management scale deployment --replicas=0 rsevents
# KUBE_EDITOR=micro k edit deployments.apps rsevents
# cat dashboard_token dashboard_url

# =======================================
# ===============[ Kafka ]===============
# =======================================
#  exec -ti into kafka
#  unset JMX_PORT
#
# -----[ General ]-----
function kafka.general(){
 # List topics:
 kafka-topics.sh --list --zookeeper zookeeper:2181

 # How many unconsumed messages in topic:
 kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group rsevents --describe --offsets | grep as-hs-events-traffic-topic | awk '{lag+=$6} END {print lag}'

 # Delete messages:
 /opt/bitnami/kafka/bin/kafka-configs.sh --bootstrap-server kafka:9092 --topic as-hs-events-traffic-topic --alter --add-config retention.ms=0
 # OR:
 sed -i 's/delete.topic.enable=false/delete.topic.enable=true/g' /opt/bitnami/kafka/config/server.properties
 /opt/bitnami/kafka/bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic as-hs-events-traffic-topic
 # OR:
 echo ' {"partitions": [{"topic": "as-hs-events-traffic-topic", "partition": 0, "offset": 80000}], "version":1 }' > offsetfile.json
 kafka-delete-records.sh --bootstrap-server localhost:9092 --offset-json-file ./offsetfile.json
 for i in $(seq 100); do kafka-delete-records.sh --bootstrap-server localhost:9092 --offset-json-file <( echo "{\"partitions\": [{\"topic\": \"as-hs-events-traffic-topic\", \"partition\": $i, \"offset\": -1}], \"version\":1 }" ); done

 # Performance test:
 kafka-consumer-perf-test.sh --bootstrap-server localhost:9092 --topic as-hs-events-traffic-topic --messages 100000 | cut -d ',' -f 5-6
}

# -----[ Publish ]-----
function kafka.publish(){
  kafka-console-producer.sh --broker-list localhost:9092 --topic as-hs-events-traffic-topic
  #>{"device_event_blocked_traffic":{"message":{"timestamp":"2021-08-23T15:53:00Z","trace_id":"trace_id"}}}
}

# -----[ Consume ]-----
function kafka.consume(){
  kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic as-hs-events-traffic-topic --from-beginning
  kafka-console-consumer.sh --bootstrap-server kafka-0:9092 --topic ...
  kafka-console-consumer.sh --bootstrap-server kafka-0:9092 --whitelist 'as-rs.*|as-rsevents.*|hs-routers.*|as-hs.*'
}

# -----[ Certs ]-----
function kafka.consume(){
  kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data['ca\.crt']}" | base64 --decode > /tmp/ca.crt
  kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data['client\.key']}" | base64 --decode > /tmp/client.key
  kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data['client\.crt']}" | base64 --decode > /tmp/client.crt
  # or (doesn't completely work):
  # shellcheck disable=SC2259
  ssh $todd kubectl -n secure-management get secret kafka-external-certificates -o jsonpath="{.data}" \
    | python3 <<-EOF
  import json, sys, base64
  data = json.loads(sys.stdin.read())
  def decode(key):
      return base64.decodebytes(data[key].encode()).decode()
  print(decode('ca.crt'))
EOF
}

# -----[ Connections ]------
function kafka.connections(){
  external_ip="$(k -n secure-management get svc | grep istio-ingress | python -c 'from sys import stdin; print(stdin.read().split()[3])')"    # e.g 10.xxx.xxx.13
  kafka_host="$(kubectl -n secure-management get vs | grep -Eo 'kafka.default.[[:alpha:]]+')"   # e.g kafka.default.todd
  ### In /etc/hosts file:
  # <external_ip> isp.default.<machine_name>
  # <external_ip> kafka.default.<machine_name>
  kafka_external_port="$(kubectl -n secure-management get svc | grep kafka-0 | grep -Po '(?<=:)\w+')"   # e.g 30094
}

# =======================================
# ===============[ Zsh ]=================
# =======================================

function setup_zsh(){
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

}
if [[ -n "$ZSH_VERSION" ]]; then
  if [[ "${SHELL##*/}" == zsh ]]; then
    setup_zsh
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