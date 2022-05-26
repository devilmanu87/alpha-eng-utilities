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
    #  p ) cp_ca_pem = "$OPTARG" ;;
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
if [[ $dry_run == "true" ]]; then
  helm upgrade --install $release_name $helm_repo  -f $values_yaml_file -n $namespace --dry-run
else  
  helm upgrade --install $release_name $helm_repo  -f $values_yaml_file -n $namespace --create-namespace
fi  

#Done manually today, since next version of ADO we have to revamp.
#az keyvault secret set --vault-name "it-kv-001-int-eastus" --name "srv-crddev-obscoadm-server-crt" --disabled false --file srv_crddev_obscoadm-server.crt --encoding base64
#az keyvault secret set --vault-name "it-kv-001-int-eastus" --name "srv-crddev-obscoadm-server-key" --disabled false --file srv_crddev_obscoadm-server.key --encoding base64
#kubectl create ns alpha-tracing 
#kubectl -n alpha-tracing create secret tls cp-tls --cert=srv_crddev_obscoadm-server.crt --key=srv_crddev_obscoadm-server.key
#kubectl -n alpha-tracing create secret generic cp-ca --from-file=ConfluentQA-CA.pem

