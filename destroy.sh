#!/bin/bash

HOSTED_ZONE="opsora.space"
ZONE_ID="Z0738852208EFDOYXFTUB"
SERVICES=( "frontend" "backend" "mysql" )

for instance in "${SERVICES[@]}"; do
  # Find existing instance ID
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$instance" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

  if [ -n "$INSTANCE_ID" ]; then
    echo "Terminating ${instance} instance: ${INSTANCE_ID}"
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
  else
    echo "No instance found for ${instance}, skipping termination."
    continue
  fi

  # DNS record name logic
  if [[ "$instance" == "frontend" ]]; then
    RECORD_NAME=$HOSTED_ZONE
  else
    RECORD_NAME="${instance}.${HOSTED_ZONE}"
  fi

  # Delete DNS record
  IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text)

  echo "Removing DNS record: ${RECORD_NAME}"

  aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "{
    \"Comment\": \"Delete A record\",
    \"Changes\": [
      {
        \"Action\": \"DELETE\",
        \"ResourceRecordSet\": {
          \"Name\": \"${RECORD_NAME}\",
          \"Type\": \"A\",
          \"TTL\": 60,
          \"ResourceRecords\": [
            { \"Value\": \"${IP}\" }
          ]
        }
      }
    ]
  }"

  echo "DNS record deleted: ${RECORD_NAME}"
done
