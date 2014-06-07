#!/bin/sh
sed -i -e "s/^.*api_key:.*$/api_key: ${DATADOG_API_KEY:?"must be set"}/" /etc/dd-agent/datadog.conf
exec /usr/bin/supervisord -n -c /etc/dd-agent/supervisor.conf
