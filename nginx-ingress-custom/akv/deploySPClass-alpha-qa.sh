#!/bin/bash

echo "Deployment Date-Time: $(date +%m%d%y-%H%M%S)"
echo ""

ALLOWED_NAMESPACES="alpha-logging"
NAMESPACES=$(kubectl get ns | egrep -i "NAME|$ALLOWED_NAMESPACES" | awk '{print $1}' | awk '(NR>1)' | tr '\n' ' ')

echo $NAMESPACES

for ns in $NAMESPACES
do
  echo "Deploying SecretProviderClass to namespace: $ns"
  kubectl apply -f secretproviderclass-nginx-alpha-qa.yaml -n $ns

  echo "check and create the secret!!"
  spccsisecret=$(kubectl get secret -n $ns | grep ac-eng-cpe-spn-devops-001-secrets | awk '{print $1}' | tr '\n' ' ')
  echo $spccsisecret

  if [ -z "$spccsisecret" ]
  then
    echo "Create K8S secret with the SPN to access the AKV";
    kubectl create secret generic ac-eng-cpe-spn-devops-001-secrets --from-literal clientid=0d86580f-e839-4fd7-8397-f70d43b3a870 --from-literal clientsecret=$(az keyvault secret show --id https://it-kv-001-int-eastus.vault.azure.net/secrets/ac-eng-cpe-spn-devops-001 -o tsv --query "value") -n $ns
  else
    echo "K8S secret with the SPN to access the AKV already exists!!!";
  fi
done
echo ""
echo "Checking for deployed SecretProviderClass..."
kubectl get secretproviderclass -n $ns -A
echo ""
echo "Deployment is now complete!!"
