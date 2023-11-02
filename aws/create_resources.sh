#!/bin/bash

PROJECT_TAG="project"
OWNER_TAG="owner"
REGION="eu-west-1"
AMI_ID="ami-0a7abae115fc0f825"
VPC_NAME="my-vpc"
SUBNET_NAME="my-subnet"
ECR_NAME="my-ecr"
INSTANCE_NAME="my-ec2-instance"
SG_NAME="my-security-group"
KEY_NAME="myKey.pem"
EC2_NAME="my-instance"
IG_NAME="my-internet-gateway"
ROUTE_TABLE_NAME="my-route-table"
ELASTIC_IP_NAME="my-public-ip"
ACCOUNT_ID="id"
INSTANCE_PROFILE_NAME="ECRAccessRole"

# Create a VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 --region $REGION \
    --query 'Vpc.VpcId' --output text \
	--tag-specifications "ResourceType=vpc,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$VPC_NAME}]")
echo "Created VPC with ID: $VPC_ID"

# Create a Subnet
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID --cidr-block 10.0.0.0/24 \
    --query 'Subnet.SubnetId' --output text \
	--tag-specifications "ResourceType=subnet,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$SUBNET_NAME}]")
echo "Created Subnet with ID: $SUBNET_ID"

# Create a Security Group
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --vpc-id $VPC_ID --region $REGION \
    --group-name $SG_NAME --description 'My Security Group' \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$SG_NAME}]" \
    --query 'GroupId' --output text)
echo "Created Security Group with ID: $SECURITY_GROUP_ID"

# Allow SSH traffic
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION
echo "Added rule to SG (allow ssh traffic)"

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION
echo "Added rule to SG (allow http traffic)"

# Create a Key Pair
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' --output text > $KEY_NAME
chmod 400 $KEY_NAME
echo "Created Key Pair"

# Create a private ECR Repository
ECR_REPO_URI=$(aws ecr create-repository \
    --repository-name my-spring-petclinic-repo --region $REGION \
    --tags Key=Project,Value=$PROJECT_TAG Key=Owner,Value=$OWNER_TAG Key=Name,Value=$ECR_NAME \
    --query 'repositories[0].repositoryUri' --output text)

ECR_REPO_URI=$(aws ecr describe-repositories \
    --repository-names my-spring-petclinic-repo \
    --region $REGION --query 'repositories[0].repositoryUri' --output text)
echo "Created ECR Repo with URI: $ECR_REPO_URI"

# Authenticate Docker to your ECR repository
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

# Tag your Docker image with the ECR repository URI
docker tag spring-petclinic:latest $ECR_REPO_URI:spring-petclinic

# Push the image to ECR
docker push $ECR_REPO_URI:spring-petclinic

# Create IAM policy
aws iam create-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME
aws iam add-role-to-instance-profile --role-name EcrRegistryFullAccessEc2 --instance-profile-name $INSTANCE_PROFILE_NAME

# Launch an EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID --instance-type t2.micro \
    --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --iam-instance-profile Name=$INSTANCE_PROFILE_NAME \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$EC2_NAME}]" \
    --query 'Instances[0].InstanceId' --output text)
echo "Created instance with ID: $INSTANCE_ID"

aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
    --region $REGION \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$IG_NAME}]" \
    --query 'InternetGateway.InternetGatewayId' --output text)
echo "Created Internet Gateway with ID: $INTERNET_GATEWAY_ID"

# Attach an Internet Gateway
aws ec2 attach-internet-gateway \
    --internet-gateway-id $INTERNET_GATEWAY_ID \
    --vpc-id $VPC_ID --region $REGION
echo "Attached IG"

# Create Route Table
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID --region $REGION \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$ROUTE_TABLE_NAME}]" \
    --query 'RouteTable.RouteTableId' --output text)
echo "Created route table with ID: $ROUTE_TABLE_ID"

# Associate Route Table with Subnet
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID

# Add Route to the Route Table
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $INTERNET_GATEWAY_ID

# Allocate an Elastic IP address
PUBLIC_IP=$(aws ec2 allocate-address \
    --region $REGION \
    --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Project,Value=$PROJECT_TAG},{Key=Owner,Value=$OWNER_TAG},{Key=Name,Value=$ELASTIC_IP_NAME}]" \
    --query 'PublicIp' --output text)
echo "Allocated the Elastic IP Address: $PUBLIC_IP"

# Associate the Elastic IP with your EC2 instance
aws ec2 associate-address \
    --instance-id $INSTANCE_ID \
    --public-ip $PUBLIC_IP \
    --region $REGION
echo "Associated the Elastic IP: $PUBLIC_IP with Instance: $INSTANCE_ID"


# SSH into the EC2 instance
ssh -i $KEY_NAME ec2-user@$PUBLIC_IP << EOF

# Install Docker
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull the Docker image from ECR
docker pull $ECR_REPO_URI:spring-petclinic

# Run the container
docker run -d -p 80:8080 $ECR_REPO_URI:spring-petclinic
EOF

read -p "Press Enter to delete resources"
echo "Deleting resources..."

# Disassociate Elastic IP
aws ec2 disassociate-address --public-ip $PUBLIC_IP --region $REGION

# Release Elastic IP
aws ec2 release-address --public-ip $PUBLIC_IP --region $REGION

# Delete the Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID --region $REGION

# Delete the EC2 instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION

# Delete the Route Table
aws ec2 disassociate-route-table --association-id $SUBNET_ID --region $REGION
aws ec2 delete-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --region $REGION
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID --region $REGION

# Delete the Subnet
aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION

# Delete the Security Group
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID --region $REGION

# Delete the Key Pair
aws ec2 delete-key-pair --key-name $KEY_NAME

# Delete the ECR Repository
aws ecr delete-repository --repository-name my-spring-petclinic-repo --force --region $REGION
aws ecr wait repository-deleted --repository-name my-spring-petclinic-repo --region $REGION

# Delete the VPC
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

# Delete the IAM Instance Profile
aws iam remove-role-from-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --role-name EcrRegistryFullAccessEc2
aws iam delete-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME

echo "Script execution completed."
