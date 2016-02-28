#!/bin/bash
#set -e

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /etc/dd-agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run the Datadog Agent container"
	exit 1
fi

if [[ $TAGS ]]; then
	sed -i -e "s/^#tags:.*$/tags: ${TAGS}/" /etc/dd-agent/datadog.conf
fi

if [[ $LOG_LEVEL ]]; then
    sed -i -e"s/^.*log_level:.*$/log_level: ${LOG_LEVEL}/" /etc/dd-agent/datadog.conf
fi

if [[ $DD_URL ]]; then
    sed -i -e 's@^.*dd_url:.*$@dd_url: '${DD_URL}'@' /etc/dd-agent/datadog.conf
fi

if [[ $PROXY_HOST ]]; then
    sed -i -e "s/^# proxy_host:.*$/proxy_host: ${PROXY_HOST}/" /etc/dd-agent/datadog.conf
fi

if [[ $PROXY_PORT ]]; then
    sed -i -e "s/^# proxy_port:.*$/proxy_port: ${PROXY_PORT}/" /etc/dd-agent/datadog.conf
fi

if [[ $PROXY_USER ]]; then
    sed -i -e "s/^# proxy_user:.*$/proxy_user: ${PROXY_USER}/" /etc/dd-agent/datadog.conf
fi

if [[ $PROXY_PASSWORD ]]; then
    sed -i -e "s/^# proxy_password:.*$/proxy_password: ${PROXY_USER}/" /etc/dd-agent/datadog.conf
fi

if [[ $STATSD_METRIC_NAMESPACE ]]; then
    sed -i -e "s/^# statsd_metric_namespace:.*$/statsd_metric_namespace: ${STATSD_METRIC_NAMESPACE}/" /etc/dd-agent/datadog.conf
fi

find /conf.d -name '*.yaml' -exec cp {} /etc/dd-agent/conf.d \;

# replacing env var templates with env var values, for instance: ${SHELL} with /bin/bash
for file in /etc/dd-agent/conf.d/*.yaml; do
 if [ -f "$file" ]
 then
  # create temp file
  echo -n "" > "$file".tmp
  while read -r line ; do
     while [[ "$line" =~ (\$\{[a-zA-Z_][a-zA-Z_0-9]*\}) ]] ; do
         LHS=${BASH_REMATCH[1]}
         RHS="$(eval echo "\"$LHS\"")"
         line=${line//$LHS/$RHS}
     done
     # echo the processed line to the temp file
     echo "$line" >> "$file".tmp
  done < "$file"

  # write the temp file instead of the original file
  cat "$file".tmp > "$file"
  # delete the temp file
  rm "$file".tmp
 fi
done


find /checks.d -name '*.py' -exec cp {} /etc/dd-agent/checks.d \;

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

if [[ $DOGSTATSD_ONLY ]]; then
		PYTHONPATH=/opt/datadog-agent/agent /opt/datadog-agent/embedded/bin/python /opt/datadog-agent/agent/dogstatsd.py
else
		exec "$@"
fi
