#!/bin/bash

TO_ADDRESS=$1
TXN_ID=$2
DESCRIPTION=$3
AMOUNT=$4
TOTAL_EXPENSE=$5
SUBJECT=$6

EMAIL_BODY=$(sed -e "s|TXN_ID|$TXN_ID|g" \
                  -e "s|DESCRIPTION|$DESCRIPTION|g" \
                  -e "s|AMOUNT|$AMOUNT|g" \
                  -e "s|TOTAL_EXPENSE|$TOTAL_EXPENSE|g" mail.html)

{
echo "To: $TO_ADDRESS"
echo "Subject: $SUBJECT"
echo "Content-Type: text/html"
echo ""
echo "$EMAIL_BODY"
} | msmtp "$TO_ADDRESS"