#!/usr/bin/env bash

#set -o pipefail
#set +o xtrace

red=$(tput setaf 1)
green=$(tput setaf 2)
reset=$(tput sgr0)

function os_type() {
    OS=${OSTYPE//[0-9.-]*/}
    case "$OS" in
        darwin) machine=Mac ;;
        linux)  machine=Linux ;;
        *)
        echo "Operating System $OSTYPE not supported, supported types are darwin, linux"
        exit 1
        ;;
    esac
}

## Find OS type
os_type

function program_is_installed() {
  local return_=0
  # set to 1 if not found
  type $1 >/dev/null 2>&1 || return_=1;
  # return value
  return ${return_}
}

function echo_fail() {
  printf "\e[31m✘ ${1}"
  printf "\033\e[0m\n"
}

function echo_pass {
  printf "\e[32m✔ ${1}"
  printf "\033\e[0m\n"
}

function die {
    echo "${red}$@${reset}"
    exit 1
}

function check_binaries() {
    local v=$1
    program_is_installed ${v} || die "Please install [$v] before running the script..."
}

function validate_k8s() {
    echo "Validating if kubernetes cluster is accessible from local machine: "
    kubectl --request-timeout='5' version &> /dev/null || die "\tKubernetes cluster access: $(echo_fail) \n"
    printf "\tKubernetes cluster access: $(echo_pass)"
}

function validate_helm() {
    echo "Validating if Helm is accessible from local machine: \n"
    helm version &> /dev/null || die "\tHelm access: $(echo_fail) \n\tPlease refer to the Operator"\
                                      " documentation for Helm troubleshooting."
    printf "\tHelm access: $(echo_pass)"
}

function validate_context() {
    if [[ -z "${context}" ]]; then
        context=$(kubectl config current-context 2> /dev/null)
        [[ $? != 0 || -z "${context}" ]] && die "\t${red}No current kubernetes context found.${reset}"
    else
        kubectl config get-contexts ${context} &> /dev/null || \
            die "Kubernetes context ${context} not found in config."
    fi
}

function validate_namespace() {
    if [[ -z "${namespace}" ]]; then
        namespace=$(kubectl --context ${context} config view --minify | grep namespace | sed "s/namespace://g" | sed "s/ //g")
        [[ -z "${namespace}" ]] && \
                 die "\t${red}Kubernetes namespace does not exists in ${context} context. Either pass one or set the "\
                 "namespace by running \n\t'kubectl config set-context --current --namespace=<insert-namespace-name-here>'."\
                 "${reset}"
    else
        kubectl --context ${context} get namespace ${namespace} &> /dev/null || run_cmd "kubectl create namespace ${namespace}" "${verbose}"
    fi

    echo "\tKubernetes Namespace:  $(echo_pass ${namespace})"
}

function required_binaries() {
    echo "Checking if required executables are installed:"
    printf "\tKubectl command installation: "
    check_binaries kubectl && echo_pass
    printf "\tHelm command Installation: "
    check_binaries helm && echo_pass
    printf "\tprintf command Installation: "
    check_binaries printf && echo_pass
    printf "\tawk command Installation: "
    check_binaries awk && echo_pass
    printf "\tcut command Installation: "
    check_binaries cut && echo_pass
}

function contains() {
  local check=$1 && shift
  local a=($@)
  local in=1
  for i in ${a[@]}; do
    if [[ "$check" = "$i" ]]; then
      in=0
    fi
  done
  return ${in}
}

function helm_folder_path() {
  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  echo $(printf "%s/../helm/confluent-operator" ${DIR})
}

function retry() {
  local retries=$1
  shift
  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1 ))
    if [[ ${count} -lt ${retries} ]]; then
      echo "Retry $count/$retries exited ${exit}, retrying in ${wait}  seconds..."
      sleep ${wait}
    else
      echo "Retry $count/$retries exited ${exit}, no more retries left."
      exit 1
      return 1
    fi
  done

  return 0
}

function run_cmd() {
  enable_debug=$2
  echo "Run Command:"
  printf "\t${green}$1${reset}\n"
  if [[ ${enable_debug} = "true" ]]; then
    eval $1
  else
    val=$(eval $1 2>&1)
  fi
  if [[ $? != 0 ]]; then
      die "${red}Unable to execute ${1} ${val} ${reset}\n"
  fi
}

function run_helm_command() {

  local script_path="$1"
  local service="$2"
  local dry_run="$3"
  local helm_basedir=$(helm_folder_path)
  local helm_version
  helm_version=$(get_helm_version) || { echo ${helm_version}; exit 1; }
  if [[ ${upgrade} == "true" ]]; then
     operator=$(printf "helm --kube-context ${context} upgrade --install -f %s %s %s %s --namespace %s %s" "${script_path}" "${helm_args}" "${service}" "${helm_basedir}" "${namespace}" "${dry_run}")
  else
     if [[ "${helm_version}" == "v2" ]]; then
        operator=$(printf "helm --kube-context ${context} install -f %s --name %s %s --namespace %s %s" "${script_path}" "${service}" "${helm_basedir}" "${namespace}" "${helm_args}")
     elif [[ "${helm_version}" == "v3" ]]; then
        operator=$(printf "helm --kube-context ${context} install -f %s %s %s --namespace %s %s" "${script_path}" "${service}" "${helm_basedir}" "${namespace}" "${helm_args}")
     fi
  fi
  echo "$operator"
}

function wait_for_k8s_sts() {
  local kubectl_cmd="kubectl --context ${context} -n ${namespace}"
  echo "sts: " ${sts_name}
  retry ${retries} kubectl -n ${namespace} --context ${context} get sts ${sts_name}
  run_cmd "${kubectl_cmd} rollout status sts/${sts_name} -w" ${verbose}
}

function run_cp() {

  local helm_file_path="$1"
  local helm_version
  helm_version=$(get_helm_version) || { echo ${helm_version}; exit 1; }
  local helm_common_args
  if [[ "${helm_version}" == "v2" ]]; then
    helm_common_args="--wait --timeout 600"
  elif [[ "${helm_version}" == "v3" ]]; then
    helm_common_args="--wait --timeout 600s"
  fi
  local kubectl_cmd="kubectl --context ${context} -n ${namespace}"
  
  helm_args="${custom_args} ${helm_common_args}"
  component=`echo ${custom_args} | awk -F\.enabled=true '{print $1}' | awk '{ print $NF }'`
  if [[ $component = @(zookeeper|kafka) ]]; then
     psc=$component"clusters.cluster.confluent.com"
  else
     psc="psc"	  
  fi
  
  if [ $component = "operator" ]; then
  	echo "-------- Dry Run-------"
        run_cmd "$(run_helm_command ${helm_file_path} "${release_prefix}-${component}" "--dry-run")" ${verbose}
	echo "-------- Dry Run End----"
	run_cmd "$(run_helm_command ${helm_file_path} "${release_prefix}-${component}" "")" ${verbose}
  else 
  	echo "-------- Dry Run-------"
 	run_cmd "$(run_helm_command ${helm_file_path} "${release_prefix}-${component}" "--dry-run")" ${verbose}
	echo "-------- Dry Run End----"
	run_cmd "$(run_helm_command ${helm_file_path} "${release_prefix}-${component}" "")" ${verbose}
  	sts_name=$(kubectl --context ${context} -n ${namespace} get $psc -l component=${component} -o jsonpath='{.items[*].metadata.name}')
  	wait_for_k8s_sts 
  fi
}

function get_helm_version() {
    local helm_version=$(helm version -c --short | awk '{print $NF}' | cut -f1 -d'.')
    if [[ "${helm_version}" != "v2" && "${helm_version}" != "v3" ]]; then
        echo "Helm is neither version v2 or v3, found version ${helm_version}"
        return 1
    fi
    echo "${helm_version}"
}

function usage() {
    echo "usage: ./spoke-util.sh -r <release_prefix> -f <helm yaml> -a <custom-arguments>"
    echo "   ";
    echo "  -n | --namespace       : kubernetes namespace to use, by default, uses the current context's namespace if present (required)";
    echo "  -a | --custom-arguments: Custom Arguments to pass while running helm install command, it should pass within " " (required)";
    echo "  -f | --helm-file       : provide helm chart's values.yaml file, e.g /tmp/values.yaml";
    echo "  -r | --release-prefix  : release name prefix (required)";
    echo "  -v | --verbose         : enable verbose logging";
    echo "  -u | --upgrade         : Upgrade Confluent Platform";
    echo "  -e | --retries         : retries for kubernetes resources, default 10 times with exponential backoff";
    echo "  -h | --help            : Usage command";
}

function parse_args {
    args=()
    while [[ "$1" != "" ]]; do
        case "$1" in
            -a | --custom-arguments )     custom_args="${2}";        shift;;
            -n | --namespace )            namespace="${2}";          shift;;
            -r | --release-prefix)        release_prefix="${2}";     shift;;
            -f | --helm-file)             values_file="${2}";        shift;;
            -e | --retry )                retries="${2}";            shift;;
            -u | --upgrade )              upgrade="true";            ;;
            -v | --verbose )              verbose="true";            ;;
            -h | --help )                 help="true";               shift;;
            * )                           args+=("$1")
        esac
        shift
    done

    set -- "${args[@]}"

    if [[ ! -z ${help} ]]; then
      usage
      exit
    fi

    if [ -z ${release_prefix} ] || [ -z ${namespace} ] || [ -z ${values_file} ]; then
        usage
        die "Please provide all mandatory parameters"
    fi


    # set verbose logging
    if [[ -z ${verbose} ]]; then
       verbose="true"
    fi

    # set upgrade
    if [[ -z ${upgrade} ]]; then
        upgrade="true"
    fi

    ## retry states
    if [[ -z ${retries} ]]; then
        retries=5
    fi

    if [[ -z ${custom_args} ]]; then
        custom_args=""
    fi
}

function run() {
  parse_args "$@"

  echo "Confluent Platform Deployment:"

  required_binaries

  validate_k8s

  validate_helm

  validate_context

  validate_namespace

  [[ -z  ${values_file} || ! -f ${values_file} ]] && die "\tHelm file ${values_file} does not exist: $(echo_fail)\n
                                                          \tPass in a valid helm file."

  run_cp ${values_file}
}

run "$@";
