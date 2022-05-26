#!/bin/bash
set -e
set -o pipefail

helpFunction()
{
   echo ""
   echo "Usage: $0 -r helm-repository -n namespace -f values_yaml_file -i litmus_server -a agent_name -l agent_description -p litmus_project_id"
   echo -e "\t-r ADO Helm repository name"
   echo -e "\t-n namespace to deploy the application"
   echo -e "\t-f custom values yaml file path"
   echo -e "\t-i litmus_server endpoint URL"
   echo -e "\t-a litmus agent name"
   echo -e "\t-l litmus agent description"
   echo -e "\t-s litmus agent node selector"
   echo -e "\t-p litmus server project ID"
   echo -e "\t-d enable Dry-Run"
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:i:a:l:p:d:s" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      i ) litmus_server="$OPTARG" ;;
      a ) agent_name="$OPTARG" ;;
      l ) agent_description="$OPTARG" ;;      
      p ) litmus_project_id="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      s ) agent_node_selection="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$litmus_server" ] || [ -z "$agent_name" ] || [ -z "$agent_description" ] || [ -z "$litmus_project_id" ]
then
   echo $helm_repo
   echo $namespace
   echo $values_yaml_file
   echo $litmus_server
   echo $agent_name
   echo $agent_description
   echo $litmus_project_id
   echo "Some or all of the parameters are empty";
   helpFunction
fi

#### Shell and Helm commands start from here

echo "Installing Litmus Agent to the Cluster"
pwd

ls -lrt /usr/local/bin/litmusctl

echo "litmusctl set account"
litmusctl config set-account --endpoint="$litmus_server" --username="admin" --password="litmus"

echo "litmusctl config"
litmusctl config view

echo "litmusctl get-accounts"
litmusctl config get-accounts

if [[ $dry_run == "true" ]]; then
   litmusctl get agents --project-id=$litmus_project_id
else
   echo $agent_node_selection
   if [ -z "$agent_node_selection" ]
   then
      litmusctl create agent --agent-name="$agent_name" --agent-description="$agent_description" --cluster-type="external" --installation-mode="cluster" --kubeconfig=./kube-config --project-id=$litmus_project_id --non-interactive
   else
      litmusctl create agent --agent-name="$agent_name" --agent-description="$agent_description" --cluster-type="external" --installation-mode="cluster" --kubeconfig=./kube-config --node-selector=$agent_node_selection --project-id=$litmus_project_id --non-interactive
   fi
fi



