#! /bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -s source-acr-registry -d destination-acr-registry -f images-file-path -t custom-tag-path"
   echo -e "\t-s Source ACR registry to pull images"
   echo -e "\t-d Destination ACR registry to push images"
   echo -e "\t-f Images file path to pull images from opensource"
   echo -e "\t-t Custom Image tag name eg: alpha-confluent"
   exit 1 # Exit script after printing help
}

while getopts "s:d:f:t:" opt
do
   case "$opt" in
      s ) s_acr="$OPTARG" ;;
      d ) d_acr="$OPTARG" ;;
      f ) file_path="$OPTARG" ;;
      t ) tag="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$s_acr" ] || [ -z "$d_acr" ] || [ -z "$file_path" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

####### Begin the Script ##############
#az acr login -n "$acr" # Login to Azure ACR

while IFS= read image
do
    if [ $s_acr = $d_acr ]; then
      echo "--------Pull image from $image--------"
      docker pull "$image"
      if [ $tag ]; then
         docker tag "$image" "$d_acr".azurecr.io/$tag/$image
      else
         docker tag "$image" "$d_acr".azurecr.io/$image
      fi      
    else
      echo "--------Pull image from $s_acr.azurecr.io/$tag/$image--------"
      if [ $tag ]; then
         docker pull "$s_acr".azurecr.io/$tag/$image
         docker tag "$s_acr".azurecr.io/$tag/$image "$d_acr".azurecr.io/$tag/$image
      else
         docker pull "$s_acr".azurecr.io/$image
         docker tag "$s_acr".azurecr.io/$image "$d_acr".azurecr.io/$image        
      fi
    fi
    echo "--------Push image to $d_acr.azurecr.io/$tag/$image --------"
    if [ $tag ]; then
      docker push "$d_acr".azurecr.io/$tag/$image
    else
      docker push "$d_acr".azurecr.io/$image      
    fi
    echo ""	
done <"$file_path"
