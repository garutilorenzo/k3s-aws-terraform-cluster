import os,sys,socket
from kubernetes import client, config
from kubernetes.client import configuration
import boto3

KUBECONFIG_SECRET_NAME=os.getenv('KUBECONFIG_SECRET_NAME')
SPOT_INTERRUPTION_TYPE="EC2 Spot Instance Interruption Warning"

def lambda_handler(event, context):
    
    # DEBUG
    print(event)

    print("Lambda function ARN:", context.invoked_function_arn)
    print("CloudWatch log stream name:", context.log_stream_name)
    print("CloudWatch log group name:",  context.log_group_name)
    print("Lambda Request ID:", context.aws_request_id)
    print("Lambda function memory limits in MB:", context.memory_limit_in_mb)
    print("Lambda time remaining in MS:", context.get_remaining_time_in_millis())

    # END DEBUG

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
    detail_type = None
    event_detail = {}

    if event.get('detail-type'):
        detail_type = event['detail-type']

    if event.get('detail'):
        event_detail = event['detail']

    if detail_type == SPOT_INTERRUPTION_TYPE:
        instance_interrupted = event_detail.get('instance-id')
        instance_action = event_detail.get('instance-action')
    
    if instance_interrupted and instance_action == 'terminate':
        print('delete')
        del_ret = v1.delete_node(instance_interrupted)
        print(del_ret)


# Test Payload
# {
#   "version": "0",
#   "id": "1e5527d7-bb36-4607-3370-4164db56a40e",
#   "detail-type": "EC2 Spot Instance Interruption Warning",
#   "source": "aws.ec2",
#   "account": "123456789012",
#   "time": "1970-01-01T00:00:00Z",
#   "region": "us-east-1",
#   "resources": ["arn:aws:ec2:us-east-1b:instance/i-0b662ef9931388ba0"],
#   "detail": {
#     "instance-id": "i-0b662ef9931388ba0",
#     "instance-action": "terminate"
#   }
# }