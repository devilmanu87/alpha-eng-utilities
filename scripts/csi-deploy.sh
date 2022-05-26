#!/bin/bash
set -e
set -o pipefail

helpFunction()
{
   echo ""
   echo "Usage: $0 -r helm-repository -n namespace -f values_yaml_file"
   echo -e "\t-r ADO Helm repository name"
   echo -e "\t-n namespace to deploy the application"
   echo -e "\t-f custom values yaml file path"
   echo -e "\t-d enable Dry-Run"
   echo -e "\t-z Release Name"
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:d:z:" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      z ) release_name="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$release_name" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
   exit 100
fi

#### Shell and Helm commands start from here

if [[ $dry_run == "true" ]]; then  
  helm upgrade --install $release_name -f $values_yaml_file $helm_repo/csi-secrets-store-provider-azure -n $namespace --dry-run
else
  helm upgrade --install $release_name -f $values_yaml_file $helm_repo/csi-secrets-store-provider-azure -n $namespace --create-namespace
  #sleep 10
  #kubectl get all -n $namespace
fi

