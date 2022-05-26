import os, sys
import yaml, json
import subprocess

def does_nested_key_exists(dictionary, nested_key):
    image_out=[]
    if nested_key in dictionary:
        image_out.append(dictionary[nested_key])
    for k in dictionary:
        if isinstance(dictionary[k], list) and dictionary[k] and dict in dictionary[k]:
            for i in dictionary[k]:
                for j in does_nested_key_exists(i, nested_key):
                    image_out.append(j)
        elif isinstance(dictionary[k], dict) and dictionary[k]:
            for j in does_nested_key_exists(dictionary[k], nested_key):
                image_out.append(j)
    return image_out

def run_shell_command(command):
    out = subprocess.Popen(command, shell=True,
           stdout=subprocess.PIPE,
           stderr=subprocess.STDOUT)
    stdout,stderr = out.communicate()
    return stdout

if len(sys.argv) > 2:
    print('You have specified too many arguments, please pass a folder path to look for image names')
    sys.exit()

if len(sys.argv) < 2:
    print('You need to specify a folder path to look for image names')
    sys.exit()

input_path = sys.argv[1]

if not os.path.isdir(input_path):
    print('The path specified does not exist')
    sys.exit()

final_images={}
value_yaml_files=run_shell_command("find "+ str(input_path) +" -name values.yaml | xargs")

with open(input_path +'.txt', 'w') as myfile:
   for yaml_file in value_yaml_files.split():
      with open(yaml_file) as f:
         output_json=yaml.full_load(f)
         image_output=does_nested_key_exists(output_json, "image")
         for i in image_output:
             if isinstance(i, dict):
                if 'repository' in i.keys() and i['repository']: 
                   final_images[i['repository']] = i['tag']
                   tag=":"+ str(i['tag']) if i['tag'] else ""
                   myfile.write(str(i['repository'])+ tag +'\n')
                   print(str(i['repository'])+ tag)
                elif 'name' in i.keys() and i['name']:
                   final_images[i['name']] = i['tag']
                   tag=":"+ str(i['tag']) if i['tag'] else ""
                   myfile.write(str(i['name'])+ tag + '\n')
                   print(str(i['name'])+ tag)

myfile.close()
