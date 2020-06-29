#!/bin/bash

set -e

function log() {
    echo "$(date +%Y%m%dT%H%M%S) - $1"
}

for VAR in MYSQL_DEFAULTS_EXTRA_FILE \
           TEMP_DIR \
           CONFIG_FILE \
           S3_BUCKET_NAME \
           AWS_ACCESS_KEY_ID \
           AWS_SECRET_ACCESS_KEY \
           AWS_DEFAULT_REGION
do
    if [[ ! "${!VAR}" ]]; then
        echo "${VAR} not defined"
        COUNT=$((COUNT + 1))
    fi
done

[[ $COUNT -gt 0 ]] && exit 1

TIMESTAMP=$(date +%Y%m%dT%H%M%S)

# We have python in the image as we have the aws client.
# Let's do this there instead something unsafe in bash
DB_HOST=$(python -c "import yaml,urllib.parse; print(urllib.parse.urlparse(yaml.safe_load(open('$CONFIG_FILE'))['DB_URI']).hostname)")

cd "${TEMP_DIR}"

log "Querying the database"
MYSQL_CMD="mysql --defaults-extra-file=${MYSQL_DEFAULTS_EXTRA_FILE} -h ${DB_HOST}"
$MYSQL_CMD -e 'show full processlist;' > "processlist-${TIMESTAMP}.txt"
$MYSQL_CMD -e 'SELECT * from information_schema.innodb_trx' > "transactions-${TIMESTAMP}.txt"
$MYSQL_CMD -e 'SELECT r.trx_id waiting_trx_id, r.trx_mysql_thread_id waiting_thread, b.trx_id blocking_trx_id, b.trx_mysql_thread_id blocking_thread, b.trx_query blocking_query FROM information_schema.innodb_lock_waits w INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;' > "transaction_locks-${TIMESTAMP}.txt"

log "Creating tar file"
TAR_FILE="diag-${TIMESTAMP}.tar.gz"
tar czf "${TAR_FILE}" *.txt

log "Copying tar file to S3"
aws s3 cp "${TAR_FILE}" "s3://$S3_BUCKET_NAME"
