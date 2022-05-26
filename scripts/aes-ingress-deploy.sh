#!/bin/bash
set -e
set -o pipefail

helpFunction()
{
   echo ""
   echo "Usage: $0 -r helm-repository -n namespace -f values_yaml_file -a akv_name"
   echo -e "\t-r ADO Helm repository name"
   echo -e "\t-n namespace to deploy the application"
   echo -e "\t-f custom values yaml file path"
   echo -e "\t-d enable Dry-Run"
   echo -e "\t-z Release Name"
   echo -e "\t-a AKV Name"
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:d:z:a:" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      z ) release_name="$OPTARG" ;;
      a ) akv_name="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$release_name" ] || [ -z "$akv_name" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
   exit 100
fi


#### Shell and Helm commands start from here
if [[ $dry_run == "true" ]]; then
   # kubectl create secret generic ${release_name}-ambassador-edge-stack --from-literal license-key=$(az keyvault secret show --id https://${akv_name}.vault.azure.net/secrets/ambassador-license-key -o tsv --query "value") --dry-run="server"

   helm upgrade --install $release_name $helm_repo  -f $values_yaml_file -n $namespace --set licenseKey.value=$(az keyvault secret show --id https://${akv_name}.vault.azure.net/secrets/ambassador-license-key -o tsv --query "value") --set licenseKey.secretName=ambassador-edge-stack --dry-run
else  
   # Create license secret from AGRID HUB KV
   # kubectl create secret generic ${release_name}-ambassador-edge-stack --from-literal license-key=$(az keyvault secret show --id https://${akv_name}.vault.azure.net/secrets/ambassador-license-key -o tsv --query "value")

   helm upgrade --install $release_name $helm_repo  -f $values_yaml_file -n $namespace --set licenseKey.value=$(az keyvault secret show --id https://${akv_name}.vault.azure.net/secrets/ambassador-license-key -o tsv --query "value") --set licenseKey.secretName=ambassador-edge-stack --create-namespace
fi  
