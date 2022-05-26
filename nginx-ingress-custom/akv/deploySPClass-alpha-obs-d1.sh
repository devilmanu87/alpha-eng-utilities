#!/bin/bash

echo "Deployment Date-Time: $(date +%m%d%y-%H%M%S)"
echo ""

ALLOWED_NAMESPACES="alpha-logging"
NAMESPACES=$(kubectl get ns | egrep -i "NAME|$ALLOWED_NAMESPACES" | awk '{print $1}' | awk '(NR>1)' | tr '\n' ' ')

echo $NAMESPACES

for ns in $NAMESPACES
do
  echo "Deploying SecretProviderClass to namespace: $ns"
  kubectl apply -f secretproviderclass-nginx-alpha-d1.yaml -n $ns

  echo "check and create the secret!!"
  spccsisecret=$(kubectl get secret -n $ns | grep agrid-cpe-d1-akv-ro-obs-spn-01-secrets | awk '{print $1}' | tr '\n' ' ')
  echo $spccsisecret

  if [ -z "$spccsisecret" ]
  then
    echo "Create K8S secret with the SPN to access the AKV";
    kubectl create secret generic agrid-cpe-d1-akv-ro-obs-spn-01-secrets --from-literal clientid=e7f2a49d-1602-493a-b61d-ac007bdc2462 --from-literal clientsecret=$(az keyvault secret show --id https://agrid-01-d1-hub-kv-001.vault.azure.net/secrets/agrid-cpe-d1-akv-ro-obs-spn-01 -o tsv --query "value")
  else
    echo "K8S secret with the SPN to access the AKV already exists!!!";
  fi
done
echo ""
echo "Checking for deployed SecretProviderClass..."
kubectl get secretproviderclass -n $ns -A
echo ""
echo "Deployment is now complete!!"
