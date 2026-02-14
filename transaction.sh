#!/bin/bash

DB_HOST="mysql-dev.opsora.space"
DB_USER="root"
DB_PASS="ExpenseApp@1"
DB_NAME="transactions"

LAST_ID_FILE="./last_txn_id.txt"

CURRENT_ID=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -e "select max(id) from transactions;" 2>/dev/null)

if [ -z "$CURRENT_ID" ]; then
  echo "DB connection failed"
  exit 1
fi

if [ ! -f "$LAST_ID_FILE" ]; then
  echo "$CURRENT_ID" > "$LAST_ID_FILE"
  exit 0
fi

LAST_ID=$(cat "$LAST_ID_FILE")

if [ "$CURRENT_ID" -gt "$LAST_ID" ]; then

  DATA=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -e "select id,amount,description from transactions where id=$CURRENT_ID;")

  TXN_ID=$(echo "$DATA" | awk '{print $1}')
  AMOUNT=$(echo "$DATA" | awk '{print $2}')
  DESCRIPTION=$(echo "$DATA" | cut -d' ' -f3-)

  TOTAL_EXPENSE=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -e "select sum(amount) from transactions;")

  SUBJECT="New Expense Alert - Transaction ${TXN_ID}"

  ./mail.sh "vihari.reddy1802@gmail.com" "$TXN_ID" "$DESCRIPTION" "$AMOUNT" "$TOTAL_EXPENSE" "$SUBJECT"

  echo "$CURRENT_ID" > "$LAST_ID_FILE"
fi
