import os,sys,socket
from kubernetes import client, config
from kubernetes.client import configuration
import boto3

KUBECONFIG_SECRET_NAME=os.getenv('KUBECONFIG_SECRET_NAME')

def lambda_handler(event, context):
    
    print(event)

    secret_client = boto3.client('secretsmanager')
    response_secret = secret_client.get_secret_value(
        SecretId=KUBECONFIG_SECRET_NAME,
    )
    if response_secret.get('SecretString'):
        open('/tmp/kubeconfig', 'w').write(response_secret['SecretString'])
        os.environ["KUBECONFIG"] = "/tmp/kubeconfig"
    
    config.load_kube_config(
        config_file=os.environ.get("KUBECONFIG", "~/.kube/config")
    ) 

    k3s_nodes = []
    v1 = client.CoreV1Api()
    ret = v1.list_node()
    for item in ret.items:
        k3s_nodes.append(item.metadata.name)
    
    instance_interrupted = None
    if event.get('detail'):
        instance_interrupted = event['detail'].get('instance-id')
    if instance_interrupted:
        print('delete')
        del_ret = v1.delete_node(instance_interrupted)
        print(del_ret)


# Test Payload
# {
#     "version": "0",
#     "id": "12345678-1234-1234-1234-123456789012",
#     "detail-type": "EC2 Spot Instance Interruption Warning",
#     "source": "aws.ec2",
#     "account": "123456789012",
#     "time": "yyyy-mm-ddThh:mm:ssZ",
#     "region": "us-east-2",
#     "resources": ["arn:aws:ec2:us-east-2:123456789012:instance/i-1234567890abcdef0"],
#     "detail": {
#         "instance-id": "i-1234567890abcdef0",
#         "instance-action": "action"
#     }
# }