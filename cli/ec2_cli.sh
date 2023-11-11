#!/bin/bash

# Usage: ./deploy-ec2.sh <private_subnet_id> <public_subnet_id> <vpc_id>

# CLI Parameters
private_subnet_id=$1
public_subnet_id=$2
vpc_id=$3
key_pair_name="my-key"
public_security_group_name="public-ec2-sg"
private_security_group_name="private-ec2-sg"

# Check if all CLI parameters are provided
if [ -z "$private_subnet_id" ] || [ -z "$public_subnet_id" ] || [ -z "$vpc_id" ]; then
  echo "Usage: $0 <private_subnet_id> <public_subnet_id> <vpc_id>"
  exit 1
fi

# Create Security Groups
public_security_group_id=$(aws ec2 create-security-group --group-name $public_security_group_name --description "Security group for public EC2" --vpc-id $vpc_id --output json | jq -r '.GroupId')

private_security_group_id=$(aws ec2 create-security-group --group-name $private_security_group_name --description "Security group for private EC2" --vpc-id $vpc_id --output json | jq -r '.GroupId')

# Allow HTTP and SSH traffic in public security group
aws ec2 authorize-security-group-ingress --group-id $public_security_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $public_security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create Private EC2 instance
private_instance_output=$(aws ec2 run-instances \
  --image-id ami-05c13eab67c5d8861 \
  --instance-type t2.micro \
  --subnet-id $private_subnet_id \
  --key-name $key_pair_name \
  --security-group-ids $private_security_group_id \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=private-ec2}]' \
  --user-data '#!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              ')

# Extract Private EC2 instance ID
private_instance_id=$(echo $private_instance_output | jq -r '.Instances[0].InstanceId')

# Wait for the Private EC2 instance to be running
aws ec2 wait instance-running --instance-ids $private_instance_id

# Create Public EC2 instance
public_instance_output=$(aws ec2 run-instances \
  --image-id ami-05c13eab67c5d8861 \
  --instance-type t2.micro \
  --subnet-id $public_subnet_id \
  --key-name $key_pair_name \
  --security-group-ids $public_security_group_id \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=public-ec2}]' \
  --user-data '#!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from public-ec2" > /var/www/html/index.html
              ping -c 3 <private_ec2_private_ip> >> /var/www/html/index.html
              ')

# Extract Public EC2 instance ID
public_instance_id=$(echo $public_instance_output | jq -r '.Instances[0].InstanceId')

# Wait for the Public EC2 instance to be running
aws ec2 wait instance-running --instance-ids $public_instance_id

echo "Private EC2 Instance ID: $private_instance_id"
echo "Public EC2 Instance ID: $public_instance_id"

