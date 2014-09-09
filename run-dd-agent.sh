#!/bin/bash

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /etc/dd-agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run the Datadog Agent container"
	exit 1
fi

if [[ $MAX_CONTAINERS ]]; then
	sed -i -e "s/^.*#max_containers:.*$/\ \ \ \ \ \ max_containers: ${MAX_CONTAINERS}/" /etc/dd-agent/conf.d/docker.yaml
fi

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

exec supervisord -n -c /etc/dd-agent/supervisor.conf
