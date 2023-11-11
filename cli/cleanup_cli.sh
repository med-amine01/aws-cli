#!/bin/bash

# Define resource IDs from command line parameters or environment variables
VPC_ID=$1
IGW_ID=$2
PUBLIC_SUBNET_ID=$3
PRIVATE_SUBNET_ID=$4
ROUTE_TABLE_ID=$5
EIP_ALLOCATION_ID=$6
NAT_GATEWAY_ID=$7

# Delete NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GATEWAY_ID

# Wait for NAT Gateway to be deleted
aws ec2 wait nat-gateway-deleted --nat-gateway-id $NAT_GATEWAY_ID

# Disassociate and delete route tables
aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_ID --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text)
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID

# Release Elastic IP address
aws ec2 release-address --allocation-id $EIP_ALLOCATION_ID

# Detach and delete Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete subnets
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "Cleanup completed."

