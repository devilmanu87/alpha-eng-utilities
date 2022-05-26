#! /bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -c context -f file_path"
   echo -e "\t-c Provide a k8s cluster context to logging into it"
   echo -e "\t-f Provide a file path to check the file exist or not"
   echo -e "\t-k Provide id_rsa keyfile path to logging into k8s cluster nodes"
   exit 1 # Exit script after printing help
}

while getopts "c:f:k:" opt
do
   case "$opt" in
      c ) context="$OPTARG" ;;
      f ) file_path="$OPTARG" ;;
      k ) idrsa_path="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$context" ] || [ -z "$file_path" ] || [ -z "$idrsa_path" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

####### Begin the Script ##############

current_context=$(kubectl config  current-context)
if [[ $current_context -ne  $context ]]
then
kubectl config use-context $context
fi

node_ips=$(kubectl get no -o json | jq -r '.items[].status.addresses[] | select(.type=="InternalIP") | .address' | xargs)
for ip in $node_ips
do
   output=$(ssh -q -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i $idrsa_path azureuser@$ip '[ -f $file_path ]' && echo "File EXISTS" || echo "File NOT FOUND\!")
   echo "For node ip $ip file $file_path: $output"
done
