# Deploy K3s on Amazon AWS

Deploy in a few minutes an high available K3s cluster on Amazon AWS using mixed on-demand and spot instances

## Requirements

* [Terraform](https://www.terraform.io/) - Terraform is an open-source infrastructure as code software tool that provides a consistent CLI workflow to manage hundreds of cloud services. Terraform codifies cloud APIs into declarative configuration files.
* [Amazon AWS Account](https://aws.amazon.com/it/console/) - Amazon AWS account with billing enabled
* [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool (optional)
* [aws cli](https://aws.amazon.com/cli/) optional

## Before you start

Note that this tutorial uses AWS resources that are outside the AWS free tier, so be careful!

## Pre flight checklist

Follow the prerequisites step on [this](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started) link.
Create a file named terraform.tfvars on the root of this repository and add your AWS_ACCESS_KEY and AWS_SECRET_KEY, example:

```
AWS_ACCESS_KEY = "xxxxxxxxxxxxxxxxx"
AWS_SECRET_KEY = "xxxxxxxxxxxxxxxxx"
```

on the vars.tf file change the following vars:

* AWS_REGION, set the correct aws region based on your needs
* PATH_TO_PUBLIC_KEY and PATH_TO_PRIVATE_KEY, this variables have tou point at your ssh public key and your ssh private key
* vpc_id, set your vpc-id. You can find your vpc_id in your AWS console (Example: vpc-xxxxx)
* vpc_subnets, set the list of your VPC subnets. You can find the list of your vpc subnets in your AWS console (Example: subnet-xxxxxx)
* vpc_subnet_cidr, set your vcp subnet cidr. You can find the VPC subnet CIDR in your AWS console (Example: 172.31.0.0/16)
* my_public_ip_cidr, your public ip in cidr format (Example: 195.102.xxx.xxx/32)

you can also change this optionals variables:

* k3s_token, the token of your K3s cluster
* cluster_name, the name of your K3s cluster
* AMIS, set the id of the amis that you will use (Note this tutorial was tested using Ubuntu 20.04)

You have to create manually an AWS IAM role named "AWSEC2ReadOnlyAccess".
You can use a custom name for this role, the name then have to be set in vars.tf in instance_profile_name variable.

The role is made by:

* AmazonEC2ReadOnlyAccess - is an AWS managed policy
* a custom inline policy for the cluster autoscaler (optional)

The inline policy is the following (Json format):

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:DescribeTags",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

For the cluster autoscaler polycy you can find more details [here](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
The full documentation for the cluster autoscaler is available [here](https://github.com/kubernetes/autoscaler)

## Notes about K3s

In this tutorial the High Availability of the K3s cluster is provided using the Embedded DB. More details [here](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/)

## Infrastructure overview

The final infrastructure will be made by:

* two autoscaling groups:
 * one autoscaling group for the server nodes named "k3s_servers"
 * one autoscaling group for the worker nodes named "k3s_workers"
* one internal load balancer that will route traffic to K3s servers
* one tharget group that will check the health of our K3s server on port 6433

the other resources created by terraform are:

* two launch templates (one for the servers and one for the workers) used by the autoscaling groups
* an ssh key pair associated with each EC2 instance
* a securiy group that will allow:
 * incoming traffic only from your public ip address on port 22 (ssh)
 * incoming traffic inside the vpc subnet on port 6443 (kube-api server)
 * outgoing traffic to the internet

Notes about the auoscaling group:

* each autoscaling group will be made by 3 EC2 instance.
* the autoscaling is configured to use a mix of spot and on-demand instances.
* the total amount of the on-demand instances is 20% so for example if we launch a total of 10 instances 2 instances will be on-demand instances.
* the autoscaling group is configured to maximize the succes of the spot request using different types of EC2 instances (See Instance used above)

You can change this setting by editing the value of on_demand_percentage_above_base_capacity in asg.tf. You can require that all the EC2 will be launced using on-demand instances setting on_demand_percentage_above_base_capacity to 100. More details [here](https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_InstancesDistribution.html)


## Instances used

The types of instances used on this tutorial are:

* t3.large (default), defined in launchtemplate.tf

The other EC2 instance types are defined/overrided in asg.tf, and are:

* t3.large, like the default one
* t2.large
* m4.large
* t3a.large

With these settings there are more probability that our spot instance request will be fullified. Also the allocation strategy is a very important settings to check. In this configurations is defined as "capacity-optimized" on asg.tf

You can change the kind of instance used editing asg.tf and launchtemplate.tf

**Very important note**

Since we are deploying a Kubernetes cluster, is **very** important that all the instances have the same amount of memory (RAM) and the same number of CPU!

## Deploy

We are now ready to deploy our infrastructure. First we ask terraform to plan the execution with:

```
terraform plan
```

if everything is ok the output should be something like:

```
...
      + name                   = "allow-strict"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "allow-strict"
        }
      + tags_all               = {
          + "Name" = "allow-strict"
        }
      + vpc_id                 = "vpc-xxxx"
    }

Plan: 10 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

```

now we can deploy our resources with:

```
terraform apply
```

After about five minutes our Kubernetes cluster will be ready. You can now ssh into one master (you can find the ips in AWS console or use the aws command line to find the ips).

If you have the aws cli installed you can find the ips of the master nodes with:

```
aws ec2 describe-instances --filters Name=tag-value,Values=k3s-server Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].[PublicIpAddress, Tags[?Key=='Name'].Value|[0]]" 
```

On one master node the you can check the status of the cluster with:

```
kubectl get nodes
```

and see all the nodes provisioned.

## Cluster resource deployed

In this setup will be automatically installed on each node of the cluster the Node termination Handler. You can find more details [here](https://github.com/aws/aws-node-termination-handler)
If for any reason you don't need the node termination handler you can edit the k3s-install-server.sh an comment the lines from 40 to 44

## Optional cluster resources

You can deploy the cluster autoscaler tool, more details [here](https://github.com/kubernetes/autoscaler).
To deploy the cluster autoscaler follow this steps:

```
wget https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

edit the cluster-autoscaler-autodiscover.yaml and change the command of the cluster-autoscaler deployment. The command is the following:

```
command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --skip-nodes-with-system-pods=false
            - --balance-similar-node-groups
            - --expander=random
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/k3s-cluster
```

we need to edit also the ssl-certs volume. The updated volume will be:

```
volumes:
        - name: ssl-certs
          hostPath:
            path: "/etc/ssl/certs/ca-certificates.crt"
```

**Note** the certificate path may change from distro to distro so adjust the value based on your needs.

Now we can deploy the cluster autscaler with:

```
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```

## Clean up

**Remember** to clean all the previously usly created resources when you have finished! We don't want surprises from AWS billing team:

```
terraform destroy
```