#!/bin/bash

set -e
# set -o pipefail

echo "Deployment Date-Time: $(date +%m%d%y-%H%M%S)"
echo ""

ALLOWED_NAMESPACES="obs-logging"
NAMESPACES=$(kubectl get ns | egrep -i "NAME|$ALLOWED_NAMESPACES" | awk '{print $1}' | awk '(NR>1)' | tr '\n' ' ')

echo $NAMESPACES
#echo $spc-csi-secret

for ns in $NAMESPACES
do
  echo "Deploying SecretProviderClass to namespace: $ns"
  kubectl apply -f ./alpha-eng-utilities/nginx-ingress-custom/akv/secretproviderclass-nginx-alpha-07-e1.yaml -n $ns

  echo "check and create the secret!!"
  SPCCSISECRET=$(kubectl get secret -n $ns | grep agrid-cpe-e1-akv-ro-obs-spn-01-secrets | tr '\n' ' ')

  if [ -z "$SPCCSISECRET" ]
  then
    echo "Create K8S secret with the SPN to access the AKV"  
    kubectl create secret -n $ns generic agrid-cpe-e1-akv-ro-obs-spn-01-secrets --from-literal clientid=0d86580f-e839-4fd7-8397-f70d43b3a870 --from-literal clientsecret=$(az keyvault secret show --id https://agrid-07-e1-hub-kv-001.vault.azure.net/secrets/ac-eng-cpe-spn-devops-001 -o tsv --query "value")
    kubectl get secret -n $ns agrid-cpe-e1-akv-ro-obs-spn-01-secrets
  else
    echo "K8S secret with the SPN to access the AKV already exists!!!"  
  fi

  
done
echo ""
echo "Checking for deployed SecretProviderClass..."
kubectl get secretproviderclass -n $ns -A
echo ""
echo "Deployment is now complete!!"
