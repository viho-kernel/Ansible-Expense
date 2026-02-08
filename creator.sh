#!/bin/bash

HOSTED_ZONE="opsora.space"
ZONE_ID="Z0738852208EFDOYXFTUB"
SG_ID="sg-0d34a14d6eba15d9d"
AMI_ID="ami-0220d79f3f480ecf5"

SERVICES=( "frontend" "backend" "mysql" )

for instance in ${SERVICES[@]};
do
   EXISTING_ID=$(
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$instance" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
   )

   if [ -n "$EXISTING_ID" ];then
     echo " ${instance} Instance is already present. Hence, skipping creation..!"
   else
      INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text
    )

    echo "Instance created ${INSTANCE_ID}"
    fi 

    if [ $instance == "frontend" ];then

    IP=$(
        aws ec2 describe-instances \
        --filters Name=instance-id,Values="$INSTANCE_ID" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' \
        --output text
    )
    RECORD_NAME=${HOSTED_ZONE}
    else
    IP=$(
        aws ec2 describe-instances \
        --filters Name=instance-id,Values="$INSTANCE_ID" \
        --query 'Reservations[*].Instances[*].PrivateIpAddress' \
        --output text
    )
    RECORD_NAME=${instance}.${HOSTED_ZONE}

    echo " IP Address of the instance ${instance} is : ${IP} "
    
    fi
    

    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" --change-batch '
    {
  "Comment": "Updating A record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'"$RECORD_NAME"'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "'$IP'"
          }
        ]
      }
    }
  ]
}

'
 echo "DNS record updated: ${RECORD_NAME} → ${IP}"

done

