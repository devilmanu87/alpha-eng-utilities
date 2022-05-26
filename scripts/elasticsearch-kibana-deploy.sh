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
   echo -e "\t-e enable elasticsearch installation"
   echo -e "\t-k enable kibana installation"
   echo -e "\t-z Elastic Release Name"   
   echo -e "\t-y Kibana Release Name"   
   exit 1 # Exit script after printing help
}

while getopts "r:n:f:d:e:k:z:y:" opt
do
   case "$opt" in
      r ) helm_repo="$OPTARG" ;;
      n ) namespace="$OPTARG" ;;
      f ) values_yaml_file="$OPTARG" ;;
      d ) dry_run="$OPTARG" ;;
      e ) elasticsearch="$OPTARG" ;;
      k ) kibana="$OPTARG" ;;
      z ) elastic_release_name="$OPTARG" ;;
      y ) kibana_release_name="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$helm_repo" ] || [ -z "$namespace" ] || [ -z "$values_yaml_file" ] || [ -z "$elastic_release_name" ] || [ -z "$kibana_release_name" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

#### Shell and Helm commands start from here

echo "Helm installation of elasticsearch and kibana"

echo "Create the small storageclass"
kubectl apply -f $helm_repo/agrid-obs-custom-storageclass.yaml
echo "Create the XL storageclass"
kubectl apply -f $helm_repo/agrid-obs-custom-storageclass-XL.yaml

if [[ $dry_run == "true" ]]; then
  helm upgrade --install $elastic_release_name $helm_repo -f $values_yaml_file -n $namespace  --set elasticsearch.enabled=$elasticsearch --render-subchart-notes --dry-run
  if [[ $? > 0 ]] ; then echo "dry-run failed"; exit 1; fi
else
  helm upgrade --install $elastic_release_name $helm_repo -f $values_yaml_file -n $namespace  --set elasticsearch.enabled=$elasticsearch --render-subchart-notes --create-namespace
  if [[ $? > 0 ]] ; then echo "deployment failed"; exit 1; fi
fi
#kubectl get all -n $namespace

if [[ $dry_run == "true" ]]; then
  helm upgrade --install $kibana_release_name $helm_repo -f $values_yaml_file -n $namespace  --set kibana.enabled=$kibana --render-subchart-notes --dry-run
  if [[ $? > 0 ]] ; then echo "dry-run failed"; exit 1; fi
else
  helm upgrade --install $kibana_release_name $helm_repo -f $values_yaml_file -n $namespace  --set kibana.enabled=$kibana --render-subchart-notes --create-namespace
  if [[ $? > 0 ]] ; then echo "deployment failed"; exit 1; fi
fi
#kubectl get all -n $namespace
