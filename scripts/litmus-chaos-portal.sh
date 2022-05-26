#!/bin/bash
set -e
set -o pipefail

helpFunction()
{
   echo ""
   echo "Usage: $0 -r helm-repository -n namespace -f values_yaml_file -i cluster_keyword -z release_name"
   echo -e "\t-r ADO Helm repository name"
   echo -e "\t-n namespace to deploy the application"
   echo -e "\t-f custom values yaml file path"
   echo -e "\t-z release name"   
   echo -e "\t-d enable Dry-Run"
   echo -e "\t-i cluster keyword"
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:z:d:i:" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      z ) release_name="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      i ) cluster_keyword="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$release_name" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

#### Shell and Helm commands start from here

echo "Installing Litmus Portal Helm deployment"
pwd

if [[ $dry_run == "true" ]]; then
  #helm upgrade --install obs-chaos ./$helm_repo/charts/litmus/ -f $values_yaml_file --namespace=obs-litmus --dry-run

  kubectl get storageclasses.storage.k8s.io
  helm upgrade --install $release_name ./$helm_repo/ -f $values_yaml_file -n $namespace --dry-run
else  
  #helm upgrade --install obs-chaos ./$helm_repo/charts/litmus/ -f $values_yaml_file --namespace=obs-litmus

  kubectl apply -f ./$helm_repo/agrid-obs-custom-storageclass.yaml
  helm upgrade --install $release_name ./$helm_repo/ -f $values_yaml_file -n $namespace --create-namespace
fi

#helm list

#kubectl get all -n $namespace

