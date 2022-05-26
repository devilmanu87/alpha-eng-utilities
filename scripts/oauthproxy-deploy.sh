#!/bin/bash
set -e
set -o pipefail

helpFunction()
{
   echo ""
   echo "Usage: $0 -r helm-repository -n namespace -f values_yaml_file -z helmchart"
   echo -e "\t-r ADO Helm repository name"
   echo -e "\t-n namespace to deploy the application"
   echo -e "\t-f custom values yaml file path"
   echo -e "\t-d enable Dry-Run"
   echo -e "\t-z helm release name"
   echo -e "\t-p Hub KV"
   echo -e "\t-p Hub Sub"
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:d:z:s:k:" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      z ) release_name="$OPTARG" ;;
      s ) hub_sub="$OPTARG" ;;
      k ) hub_kv="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$release_name" ] || [ -z "$hub_sub" ] || [ -z "$hub_kv" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

#### Shell and Helm commands start from here

echo "Installing OAuth2 Proxy"
if [[ $dry_run == "true" ]]; then
  helm upgrade --install $release_name $helm_repo -f $values_yaml_file -n $namespace --set config.clientSecret=$(az keyvault secret show --vault-name $hub_kv --subscription $hub_sub --name cpe-oauth-clientsecret --query value -o tsv) --set config.cookieSecret=$(python3 ./alpha-eng-utilities/scripts/cookie-secret.py) --set config.clientID=$(az keyvault secret show --vault-name $hub_kv --subscription $hub_sub --name cpe-oauth-clientid --query value -o tsv) --dry-run
else
  # helm uninstall $release_name -n $namespace
  echo "helm upgrade --install $release_name $helm_repo -f $values_yaml_file -n $namespace --set config.clientSecret=***** --set config.cookieSecret=$(python3 ./alpha-eng-utilities/scripts/cookie-secret.py) --set config.clientID=$(az keyvault secret show --vault-name $hub_kv --subscription $hub_sub --name cpe-oauth-clientid --query value -o tsv)"
  helm upgrade --install $release_name $helm_repo -f $values_yaml_file -n $namespace --set config.clientSecret=$(az keyvault secret show --vault-name $hub_kv --subscription $hub_sub --name cpe-oauth-clientsecret --query value -o tsv) --set config.cookieSecret=$(python3 ./alpha-eng-utilities/scripts/cookie-secret.py) --set config.clientID=$(az keyvault secret show --vault-name $hub_kv --subscription $hub_sub --name cpe-oauth-clientid --query value -o tsv) --create-namespace --wait
fi
