#!/usr/bin/python

import os, sys
import yaml, json
import subprocess
import requests
import argparse

# Initialize parser
parser = argparse.ArgumentParser()

# Adding optional argument
parser.add_argument("-f", "--yaml_file_path", help = "Provide Yaml file path for RBAC config", required=True)
parser.add_argument("-o", "--component", help = "Provide Kafka component (ex: schemaregistry, connect, replicator, controlcenter)", required=True)
parser.add_argument("-c", "--cert", help = "Provide cert file", required=True)
parser.add_argument("-k", "--key", help = "Provide key file", required=True)

# Read arguments from command line
args = parser.parse_args()

url=os.environ.get('URL')
cacert=os.environ.get('CA_CERT')
#co_cert_dir=os.environ.get('COMPONENT_CERT_DIR')
user=os.environ.get('USER')
password=os.environ.get('PASSWORD')
namespace=os.environ.get('NAMESPACE')
yaml_file=args.yaml_file_path
component=args.component
cert=args.cert
key=args.key

def post_request(path, data, headers, cert, key):
    result = requests.post(url + path,
        data=data,
        headers=headers, #dict {"Content-Type":"application/json"}
        cert=(cert,key),#key/cert pair
        verify= cacert
        )
    return result

def get_request(path, cert, key):
    headers={"Content-Type":"application/json"}
    result = requests.get(url + path,
        headers=headers, #dict {"Content-Type":"application/json"}
        auth=(user, password),
        cert=(cert,key),#key/cert pair
        verify= cacert
        )
    return result

def delete_request(path, data, user, password):
    headers={"Content-Type":"application/json"}
    result = requests.delete(url + path,
        data=data,
        headers=headers, #dict {"Content-Type":"application/json"}
        auth=(user, password),
        cert=(cert,key),#key/cert pair
        verify= cacert
        )
    return result

with open(yaml_file) as f:
    output_json=yaml.full_load(f)


for cc_component, roles in output_json.items():
     if component == cc_component: 
       print("-----------"+ cc_component + "--------------")  
       for role in roles['roles']:
           #cert=co_cert_dir + "/" + roles['cert']
           #key=co_cert_dir + "/" + roles['key']
           #Get Auth Token
           result=get_request(path="/security/1.0/authenticate", cert=cert, key=key)
           output=result.json()
           token=output['auth_token']

           #Get Kafka Cluster ID
           client_id=get_request(path="/security/1.0/metadataClusterId", cert=cert, key=key)
           kafka_id=client_id.content.decode()
           print("KAFKA_ID: "+ str(kafka_id))

           #Role Bindings
           data={"clusters":{"kafka-cluster": kafka_id}}
           path="/security/1.0/principals/User:"+ roles['user'] +"/roles/"+ role['role']
           data_resource={}
           final_data={}
           print("Role: "+ str(role['role']))
           if 'id' in role:
              data["clusters"][role['id']] = role['name']
           if 'resource' in role:
              path = path + "/bindings" 
              for r_type in role['resource']:
                 data_resource["resourceType"] = r_type
                 data_resource["name"] = role['resource'][r_type]
              if 'patternType' in role:
                 data_resource["patternType"] = role['patternType']
              else:
                 data_resource["patternType"] = "LITERAL"
           if bool(data_resource):
               final_data['scope'] = data
               final_data['resourcePatterns'] = [data_resource]
           else:
               final_data=data
           final_data=json.dumps(final_data)
           final_data=final_data.replace("${NAMESPACE}", namespace)
           final_data=''+ final_data +''
           print("Data: "+ final_data +"\n")
           headers={"Authorization": "Bearer "+ str(token) +"", "accept": "application/json", "Content-Type": "application/json"}
           result=post_request(path=path, data=final_data, headers=headers, cert=cert, key=key)
           if result.status_code != 204:
               sys.exit("Error while creating role binding for "+ role['name'] + ": Error Code "+ result.status_code)

