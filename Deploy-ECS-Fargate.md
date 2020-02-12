## Step 1: Create the Task Execution IAM Role

1. Create a file named `task-execution-assume-role.json` with the following contents

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ cat task-execution-assume-role.json 
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

2. Create the task execution role

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ aws2 iam --region ap-southeast-2 create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://task-execution-assume-role.json
{
    "Role": {
        "Path": "/",
        "RoleName": "ecsTaskExecutionRole",
        "RoleId": "AROA2CI25YS5LPHKJRRTF",
        "Arn": "arn:aws:iam::692083082426:role/ecsTaskExecutionRole",
        "CreateDate": "2020-02-12T01:06:19+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

3. Attach the task execution role policy

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ aws2 iam --region ap-southeast-2 attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

## Step 2: Configure the Amazon ECS CLI

1. Install ecs-cli

```
sudo curl -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli 

[fli@192-168-1-10 ~]$ ecs-cli --version
ecs-cli version 1.18.0 (3970a6c)
[fli@192-168-1-10 ~]$ 
```

2. Create a cluster configuration, which defines the AWS region to use, resource creation prefixes, and the cluster name to use

```
fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli configure --cluster tutorial --default-launch-type FARGATE --config-name tutorial --region ap-southeast-2
INFO[0000] Saved ECS CLI cluster configuration tutorial. 
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

3. Create a CLI profile using your access key and secret key

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli configure profile --access-key [*] --secret-key [*] --profile-name tutorial-profile
INFO[0000] Saved ECS CLI profile configuration tutorial-profile. 
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

4. ecs-cli profile location

```
[fli@192-168-1-10 ~]$ pwd
/home/fli
[fli@192-168-1-10 ~]$ cat .ecs/config 
version: v1
default: tutorial
clusters:
  tutorial:
    cluster: tutorial
    region: ap-southeast-2
    default_launch_type: FARGATE
[fli@192-168-1-10 ~]$ cat .ecs/credentials 
version: v1
default: tutorial-profile
ecs_profiles:
  tutorial-profile:
    aws_access_key_id: [*]
    aws_secret_access_key: [*]
[fli@192-168-1-10 ~]$ 
```

## Step 3: Create a Cluster and Configure the Security Group

1. Create an Amazon ECS cluster with the `ecs-cli up` command. Because you specified Fargate as your default launch type in the cluster configuration, this command creates an empty cluster and a VPC configured with two public subnets.

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli up --cluster-config tutorial --ecs-profile tutorial-profile
INFO[0001] Created cluster                               cluster=tutorial region=ap-southeast-2
INFO[0002] Waiting for your cluster resources to be created... 
INFO[0002] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
INFO[0063] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
VPC created: vpc-0342bd47c71a4d5b2
Subnet created: subnet-0369b2a5bebb3100a
Subnet created: subnet-0acefbf607f307079
Cluster creation succeeded.
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

2. Using the AWS CLI, retrieve the default security group ID for the VPC. Use the VPC ID from the previous output
```
[fli@192-168-1-10 simple-sinatra-app-infra]$ aws2 ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-0342bd47c71a4d5b2 --region ap-southeast-2
{
    "SecurityGroups": [
        {
            "Description": "default VPC security group",
            "GroupName": "default",
            "IpPermissions": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": [
                        {
                            "GroupId": "sg-0781cdef9706a6b90",
                            "UserId": "692083082426"
                        }
                    ]
                }
            ],
            "OwnerId": "692083082426",
            "GroupId": "sg-0781cdef9706a6b90",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "VpcId": "vpc-0342bd47c71a4d5b2"
        }
    ]
}
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

3. Using AWS CLI, add a security group rule to allow inbound access on port 80

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ aws2 ec2 authorize-security-group-ingress --group-id sg-0781cdef9706a6b90 --protocol tcp --port 80 --cidr 0.0.0.0/0 --region ap-southeast-2
[fli@192-168-1-10 simple-sinatra-app-infra]$ aws2 ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-0342bd47c71a4d5b2 --region ap-southeast-2{
    "SecurityGroups": [
        {
            "Description": "default VPC security group",
            "GroupName": "default",
            "IpPermissions": [
                {
                    "FromPort": 80,
                    "IpProtocol": "tcp",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "ToPort": 80,
                    "UserIdGroupPairs": []
                },
                {
                    "IpProtocol": "-1",
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": [
                        {
                            "GroupId": "sg-0781cdef9706a6b90",
                            "UserId": "692083082426"
                        }
                    ]
                }
            ],
            "OwnerId": "692083082426",
            "GroupId": "sg-0781cdef9706a6b90",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "VpcId": "vpc-0342bd47c71a4d5b2"
        }
    ]
}
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

## Step 4: Create a Compose File

1. create a simple Docker compose file that creates a simple PHP web application
```
[fli@192-168-1-10 simple-sinatra-app-infra]$ cat docker-compose.yml 
version: '3'
services:
  web:
    image: amazon/amazon-ecs-sample
    ports:
      - "80:80"
    logging:
      driver: awslogs
      options: 
        awslogs-group: tutorial
        awslogs-region: ap-southeast-2
        awslogs-stream-prefix: web
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

2. create a file named ecs-params.yml with the following content
```
[fli@192-168-1-10 simple-sinatra-app-infra]$ cat ecs-params.yml 
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 0.5GB
    cpu_limit: 256
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - "subnet-0369b2a5bebb3100a"
        - "subnet-0acefbf607f307079"
      security_groups:
        - "sg-0781cdef9706a6b90"
      assign_public_ip: ENABLED
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

## Step 5: Deploy the Compose File to a Cluster

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli compose --project-name tutorial service up --create-log-groups --cluster-config tutorial --ecs-profile tutorial-profile
INFO[0000] Using ECS task definition                     TaskDefinition="tutorial:1"
INFO[0000] Created Log Group tutorial in ap-southeast-2 
INFO[0001] Created an ECS service                        service=tutorial taskDefinition="tutorial:1"
INFO[0001] Updated ECS service successfully              desiredCount=1 force-deployment=false service=tutorial
INFO[0031] Service status                                desiredCount=1 runningCount=1 serviceName=tutorial
INFO[0031] ECS Service has reached a stable state        desiredCount=1 runningCount=1 serviceName=tutorial
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

## Step 6: View the Running Containers on a Cluster

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli compose --project-name tutorial service ps --cluster-config tutorial --ecs-profile tutorial-profile
Name                                      State    Ports                    TaskDefinition  Health
ef0ac5d0-533e-4269-8041-cf7062e976e2/web  RUNNING  13.236.188.3:80->80/tcp  tutorial:1      UNKNOWN
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

## Step 7: Scale the Tasks on the Cluster

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli compose --project-name tutorial service scale 2 --cluster-config tutorial --ecs-profile tutorial-profile
INFO[0000] Updated ECS service successfully              desiredCount=2 force-deployment=false service=tutorial
INFO[0000] Service status                                desiredCount=2 runningCount=1 serviceName=tutorial
INFO[0030] Service status                                desiredCount=2 runningCount=2 serviceName=tutorial
INFO[0030] ECS Service has reached a stable state        desiredCount=2 runningCount=2 serviceName=tutorial
[fli@192-168-1-10 simple-sinatra-app-infra]$ 

[fli@192-168-1-10 simple-sinatra-app-infra]$ ecs-cli compose --project-name tutorial service ps --cluster-config tutorial --ecs-profile tutorial-profile
Name                                      State    Ports                     TaskDefinition  Health
ef0ac5d0-533e-4269-8041-cf7062e976e2/web  RUNNING  13.236.188.3:80->80/tcp   tutorial:1      UNKNOWN
f15c47e7-75b3-4262-96b0-ca7f9da732cf/web  RUNNING  13.55.228.218:80->80/tcp  tutorial:1      UNKNOWN
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

## Step 8: View the Container Logs

```
ecs-cli logs --task-id f15c47e7-75b3-4262-96b0-ca7f9da732cf --follow --cluster-config tutorial --ecs-profile tutorial-profile
ecs-cli logs --task-id ef0ac5d0-533e-4269-8041-cf7062e976e2 --follow --cluster-config tutorial --ecs-profile tutorial-profile
```

## Step 9: (Optional) View your Web Application

Enter the IP address for the task in your web browser and you should see a webpage that displays the Simple PHP App web application.

![ecs-service-01](images/ecs-service-01.png)

## Step 10: Clean Up
When you are done with this tutorial, you should clean up your resources so they do not incur any more charges. First, delete the service so that it stops the existing containers and does not try to run any more tasks.

```
ecs-cli compose --project-name tutorial service down --cluster-config tutorial --ecs-profile tutorial-profile
```

Now, take down your cluster, which cleans up the resources that you created earlier with ecs-cli up.

```
ecs-cli down --force --cluster-config tutorial --ecs-profile tutorial-profile
```

## Appendix: resources

* resources created by manually

  1. role    

| role name | attached role policy | policy arn | trust relationship |   
| --------- | -------------------- | ---------- | ------------------ |   
| ecsTaskExecutionRole | AmazonECSTaskExecutionRolePolicy | arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy | see below |

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

  2. admin user

```
[fli@192-168-1-10 ~]$ cat .aws/credentials 
...
[fli@192-168-1-10 ~]$ cat .aws/config 
...
[fli@192-168-1-10 ~]$ 
```

* resources created by cloudformation stack

| Logical ID | Type |
| ---------- | ---- |
| AttachGateway | AWS::EC2::VPCGatewayAttachment |
| InternetGateway | AWS::EC2::InternetGateway |	
| PubSubnet1RouteTableAssociation | AWS::EC2::SubnetRouteTableAssociation |
| PubSubnet2RouteTableAssociation |	AWS::EC2::SubnetRouteTableAssociation |	
| PubSubnetAz1 | AWS::EC2::Subnet |
| PubSubnetAz2 | AWS::EC2::Subnet |	
| PublicRouteViaIgw	| AWS::EC2::Route |
| RouteViaIgw |	AWS::EC2::RouteTable |
| Vpc |	AWS::EC2::VPC |


* resources created by `ecs-cli` command

  1. ecs cluster

```
ecs cluster
region: ap-southeast-2
default_launch_type: FARGATE
service
task
```

  2. security group

```
[fli@192-168-1-10 simple-sinatra-app-infra]$ aws2 ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-0342bd47c71a4d5b2 --region ap-southeast-2
{
    "SecurityGroups": [
        {
            "Description": "default VPC security group",
            "GroupName": "default",
            "IpPermissions": [
                {
                    "FromPort": 80,
                    "IpProtocol": "tcp",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "ToPort": 80,
                    "UserIdGroupPairs": []
                },
                {
                    "IpProtocol": "-1",
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": [
                        {
                            "GroupId": "sg-0781cdef9706a6b90",
                            "UserId": "692083082426"
                        }
                    ]
                }
            ],
            "OwnerId": "692083082426",
            "GroupId": "sg-0781cdef9706a6b90",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "VpcId": "vpc-0342bd47c71a4d5b2"
        }
    ]
}
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

  3. create a simple Docker compose file that creates a simple PHP web application
```
[fli@192-168-1-10 simple-sinatra-app-infra]$ cat docker-compose.yml 
version: '3'
services:
  web:
    image: amazon/amazon-ecs-sample
    ports:
      - "80:80"
    logging:
      driver: awslogs
      options: 
        awslogs-group: tutorial
        awslogs-region: ap-southeast-2
        awslogs-stream-prefix: web
[fli@192-168-1-10 simple-sinatra-app-infra]$ 
```

  4. create a file named ecs-params.yml with the following content
```
[fli@192-168-1-10 simple-sinatra-app-infra]$ cat ecs-params.yml 
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 0.5GB
    cpu_limit: 256
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - "subnet-0369b2a5bebb3100a"
        - "subnet-0acefbf607f307079"
      security_groups:
        - "sg-0781cdef9706a6b90"
      assign_public_ip: ENABLED
[fli@192-168-1-10 simple-sinatra-app-infra]$
