#!/bin/sh

set -e

case "${ELASTICSEARCH_TLS}:${ELASTICSEARCH_TLS_VERIFY}" in
  true:true)
    WGET_SCHEMA='https://'
    CREATE_EA_OPTIONS='--ssl --verify-certs'
  ;;
  true:false)
    WGET_SCHEMA='https://'
    CREATE_EA_OPTIONS='--ssl --no-verify-certs'
  ;;
  *)
    WGET_SCHEMA='http://'
    CREATE_EA_OPTIONS='--no-ssl'
  ;;
esac

# Set the timezone.
#if [ "$SET_CONTAINER_TIMEZONE" = "true" ]; then
#        timedatectl set-timezone ${CONTAINER_TIMEZONE} && \
#	echo "Container timezone set to: $CONTAINER_TIMEZONE"
#else
#	echo "Container timezone not modified"
#fi

# Start automatic time synchronizationwith remote NTP server:
echo "Set timezone"
ln -snf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# Wait until Elasticsearch is online since otherwise Elastalert will fail.
if [ -n "$ELASTICSEARCH_USER" ] && [ -n "$ELASTICSEARCH_PASSWORD" ]; then
    WGET_AUTH="$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD@"
else
    WGET_AUTH=""
fi
while ! wget -q -T 3 -O - "${WGET_SCHEMA}${WGET_AUTH}${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}" 2>/dev/null
do
	echo "Waiting for Elasticsearch..."
	sleep 1
done
sleep 5

# Check if the Elastalert index exists in Elasticsearch and create it if it does not.
if ! wget -q -T 3 -O - "${WGET_SCHEMA}${WGET_AUTH}${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/${ELASTALERT_INDEX}" 2>/dev/null
then
    echo "Creating Elastalert index in Elasticsearch..."
    elastalert-create-index ${CREATE_EA_OPTIONS} --host "${ELASTICSEARCH_HOST}" --port "${ELASTICSEARCH_PORT}" --username "${ELASTICSEARCH_USER}" --password "${ELASTICSEARCH_PASSWORD}" --config "${ELASTALERT_CONFIG}" --index ${ELASTALERT_INDEX} --old-index ""
else
    echo "Elastalert index already exists in Elasticsearch."
fi

echo "Starting Elastalert..."
exec supervisord -c "${ELASTALERT_SUPERVISOR_CONF}" -n
