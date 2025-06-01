#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f" 
SG_ID="sg-01911fbb543963546" # replace with your SG ID sg-0004c41560075b525
SUBNET_ID="subnet-01b5dce78b401a44f"
VPC_ID="vpc-0028c24f9accf76e5"
INSTANCES=("mongodb" "catalogue" "frontend")
ZONE_ID="Z06495662WJ2QFJ1O0YBH" # replace with your ZONE ID
DOMAIN_NAME="chaliki.site" # replace with your domain


for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-01911fbb543963546 --vpc-id vpc-0028c24f9accf76e5 --subnet-id subnet-01b5dce78b401a44f --associate-public-ip-address --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        RECORD_NAME="$DOMAIN_NAME"  # adding this line to set the domain name for frontend IP Address instance
    fi
    echo "$instance IP address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
done