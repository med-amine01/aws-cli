#!/bin/bash

# Create VPC
vpc_output=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output json)
vpc_id=$(echo $vpc_output | jq -r '.Vpc.VpcId')

# Add name tag to the VPC
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=my-vpc-cli

# Create Internet Gateway
igw_output=$(aws ec2 create-internet-gateway --output json)
igw_id=$(echo $igw_output | jq -r '.InternetGateway.InternetGatewayId')

# Add name tag to the Internet Gateway
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=my-igw-cli

# Attach Internet Gateway to VPC

aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id

# Create Public Subnet
public_subnet_output=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --output json)
public_subnet_id=$(echo $public_subnet_output | jq -r '.Subnet.SubnetId')

# Add name tag to the Public Subnet
aws ec2 create-tags --resources $public_subnet_id --tags Key=Name,Value=my-public-subnet-cli

# Create Private Subnet
private_subnet_output=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --output json)
private_subnet_id=$(echo $private_subnet_output | jq -r '.Subnet.SubnetId')

# Add name tag to the Private Subnet
aws ec2 create-tags --resources $private_subnet_id --tags Key=Name,Value=my-private-subnet-cli

# Create Route Table
route_table_output=$(aws ec2 create-route-table --vpc-id $vpc_id --output json)
route_table_id=$(echo $route_table_output | jq -r '.RouteTable.RouteTableId')

# Add name tag to the Route Table
aws ec2 create-tags --resources $route_table_id --tags Key=Name,Value=my-route-table-cli

# Create a route for the public subnet to the Internet Gateway
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id

# Associate the route table with the public subnet
aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $public_subnet_id

# Allocate an Elastic IP address
eip_allocation_output=$(aws ec2 allocate-address --domain vpc --output json)
eip_allocation_id=$(echo $eip_allocation_output | jq -r '.AllocationId')

# Create NAT Gateway in the public subnet
nat_gateway_output=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $eip_allocation_id --output json)
nat_gateway_id=$(echo $nat_gateway_output | jq -r '.NatGateway.NatGatewayId')

# Add name tag to the NAT Gateway
aws ec2 create-tags --resources $nat_gateway_id --tags Key=Name,Value=my-nat-cli

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $nat_gateway_id

# Create a route for the private subnet to the NAT Gateway
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gateway_id

# Associate the route table with the private subnet
aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $private_subnet_id

echo "VPC ID: $vpc_id"
echo "Internet Gateway ID: $igw_id"
echo "Public Subnet ID: $public_subnet_id"
echo "Private Subnet ID: $private_subnet_id"
echo "Route Table ID: $route_table_id"
echo "Elastic IP Allocation ID: $eip_allocation_id"
echo "NAT Gateway ID: $nat_gateway_id"

