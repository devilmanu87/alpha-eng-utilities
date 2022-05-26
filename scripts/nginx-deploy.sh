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
   echo -e "\t-z Release Name"
   echo -e "\t-s cluster name to be used"
   echo -e "\t-d enable Dry-Run"
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:z:s:d:" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      z ) release_name="$OPTARG" ;;
      s ) clustername="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$release_name" ] || [ -z "$clustername" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

#### Shell and Helm commands start from here

#working code
#
#cd ./$helm_repo/obs-custom/akv/
#chmod +x deploySPClass-cpe-dr.sh
#dos2unix ./deploySPClass-cpe-dr.sh
#./deploySPClass-cpe-dr.sh

echo "Before script execution...."
pwd

ls -lrt 

ls -lrt ./alpha-eng-utilities/*

#Trying based on new repo structure
echo "current k8s cluster identified: $clustername"
chmod +x ./alpha-eng-utilities/nginx-ingress-custom/akv/$clustername.sh
dos2unix ./alpha-eng-utilities/nginx-ingress-custom/akv/$clustername.sh

echo "Installing NGINX chart"
pwd

#cd ../../../
if [[ $dry_run == "true" ]]; then
  #helm upgrade --install dr-ingress -f $values_yaml_file ./$helm_repo/ -n $namespace --dry-run
   helm upgrade --install $release_name -f $values_yaml_file ./$helm_repo/ -n $namespace --dry-run
else
  #helm upgrade --install dr-ingress -f $values_yaml_file ./$helm_repo/ -n $namespace
   helm upgrade --install $release_name -f $values_yaml_file ./$helm_repo/ -n $namespace --create-namespace
   ./alpha-eng-utilities/nginx-ingress-custom/akv/$clustername.sh
fi

#kubectl get all -n $namespace
