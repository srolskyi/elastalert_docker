echo "Starting Elastalert..."
supervisord -c "${ELASTALERT_SUPERVISOR_CONF}" -n
