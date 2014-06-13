#!/bin/bash

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /etc/dd-agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run DogStatsD container"
	exit 1
fi

exec /usr/bin/supervisord -n -c /etc/dd-agent/supervisor.conf
