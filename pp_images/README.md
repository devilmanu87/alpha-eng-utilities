# Readme for running the above scripts
pp_images is just a short form of Pull and Push docker images from a helm charts folder.  In pp_images folder we have two scripts one is for extracting image names from all the values.yaml in a folder. The other script is to pull all the extracted docker image from opensource and push it into our ACR registry

## Steps to run extract-images.py with its input parameters
We need to pass a helm repo folder path as a input parameter to the script. The script will check all the values.yaml for the image names and its tag. The output of this script will create a text file in the name of input folder which we provided and it contains all the image names with its tag.

```BASH
Pre-requisite:  pip install -r requirements.txt
python extract-images.py ~/acn-aks-confluent-platform
```
## Output
```BASH
itadmin@itdlaksjmp1eus1:~$ cat ~/acn-aks-confluent-platform.txt
confluentinc/cp-schema-registry-operator:6.1.0.0
confluentinc/cp-server-connect-operator:6.1.0.0
confluentinc/cp-operator-service:0.419.10
confluentinc/cp-enterprise-control-center-operator:6.1.0.0
confluentinc/cp-server-operator:6.1.0.0
confluentinc/cp-ksqldb-server-operator:6.1.0.0
confluentinc/cp-zookeeper-operator:6.1.0.0
registry.opensource.zalan.do/teapot/external-dns:v0.5.14
confluentinc/cp-enterprise-replicator-operator:6.1.0.0
confluentinc/cp-init-container-operator:6.1.0.0
```

## Steps to run upload_images.sh with its input parameters
This script will Pull all the images present in the input text file "acn-aks-confluent-platform.txt" from the opensource and push into our ACR repository. We have to provide input parameters as ACR registry name and text file path which was created by above script "extract-images.py"

## Usage of the script
```BASH
./upload_images.sh
Some or all of the parameters are empty

Usage: ./upload_images.sh -a acr-registry -f images-file-path
        -a ACR registry to push the latest images
        -f Images file path to pull images from opensource
```

## How to run the script
```BASH
./upload_images.sh -a cpeobsacr -f ~/acn-aks-confluent-platform.txt
```

## Output
The script will push all the images to ACR 
