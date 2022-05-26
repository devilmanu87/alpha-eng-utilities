# How to run ADO-operator-util.sh script
This script will deploy confluent kafka components in k8s cluster without RBAC role bindings


        prefix="cp-hub"
        values_yaml="custom yaml file path" # Created a seperate Axure repo for our custom yaml files, its under alpha-application-configs/acn-aks-confluent-platform/
        namespace="obs-kafka"

        ./ADO-operator-util.sh -r $prefix -f ../alpha-application-configs/acn-aks-confluent-platform/$values_yaml -a "$custom_args" -n $namespace

# How to run confluent-iam-restApi.py script
This script will create all the rolebindings for each component

        export NAMESPACE="obs-kafka"
        export URL="https://dr-poc-kf-be-01.crd.com:443"
        export USER="srv_crddev_obscokfk"
        export PASSWORD=$password
        export CA_CERT=<path>/ConfluentQA-CA.pem

        cert="<path>/server.crt"
        key="<path>/server.key"
        component="<component_name>" #(ex: schemaregistry, connect, replicator, controlcenter)
        rbac_yaml_file="Yaml file path" # which contains all the rbac roles and its bindings.. by default all the rbac yaml file spresent in Azure repo alpha-application-configs/acn-aks-confluent-platform
        
        python scripts/confluent-iam-restApi.py -f ../alpha-application-configs/acn-aks-confluent-platform/$(rbac_yaml_file) -o $(component) -c $cert -k $key
