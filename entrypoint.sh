#!/bin/sh
#set -e

if [[ $DD_API_KEY ]]; then
  export API_KEY=${DD_API_KEY}
fi

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /opt/datadog-agent/agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run the Datadog Agent container"
	exit 1
fi

if [[ $DD_TAGS ]]; then
  export TAGS=${DD_TAGS}
fi

if [[ $EC2_TAGS ]]; then
	sed -i -e "s/^# collect_ec2_tags.*$/collect_ec2_tags: ${EC2_TAGS}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $TAGS ]]; then
	sed -i -e "s/^#tags:.*$/tags: ${TAGS}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $DD_LOG_LEVEL ]]; then
  export LOG_LEVEL=$DD_LOG_LEVEL
fi

if [[ $LOG_LEVEL ]]; then
    sed -i -e"s/^.*log_level:.*$/log_level: ${LOG_LEVEL}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $DD_URL ]]; then
    sed -i -e 's@^.*dd_url:.*$@dd_url: '${DD_URL}'@' /opt/datadog-agent/agent/datadog.conf
fi

if [[ $PROXY_HOST ]]; then
    sed -i -e "s/^# proxy_host:.*$/proxy_host: ${PROXY_HOST}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $PROXY_PORT ]]; then
    sed -i -e "s/^# proxy_port:.*$/proxy_port: ${PROXY_PORT}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $PROXY_USER ]]; then
    sed -i -e "s/^# proxy_user:.*$/proxy_user: ${PROXY_USER}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $PROXY_PASSWORD ]]; then
    sed -i -e "s/^# proxy_password:.*$/proxy_password: ${PROXY_PASSWORD}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_BACKEND ]]; then
    sed -i -e "s/^# service_discovery_backend:.*$/service_discovery_backend: ${SD_BACKEND}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_CONFIG_BACKEND ]]; then
    sed -i -e "s/^# sd_config_backend:.*$/sd_config_backend: ${SD_CONFIG_BACKEND}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_BACKEND_HOST ]]; then
    sed -i -e "s/^# sd_backend_host:.*$/sd_backend_host: ${SD_BACKEND_HOST}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_BACKEND_PORT ]]; then
    sed -i -e "s/^# sd_backend_port:.*$/sd_backend_port: ${SD_BACKEND_PORT}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_TEMPLATE_DIR ]]; then
    sed -i -e 's@^# sd_template_dir:.*$@sd_template_dir: '${SD_TEMPLATE_DIR}'@' /opt/datadog-agent/agent/datadog.conf
fi

if [[ $STATSD_METRIC_NAMESPACE ]]; then
    sed -i -e "s/^# statsd_metric_namespace:.*$/statsd_metric_namespace: ${STATSD_METRIC_NAMESPACE}/" /opt/datadog-agent/agent/datadog.conf
fi


find /conf.d -name '*.yaml' -exec cp {} /opt/datadog-agent/agent/conf.d \;

find /checks.d -name '*.py' -exec cp {} /opt/datadog-agent/agent/checks.d \;

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

if [[ $DOGSTATSD_ONLY ]]; then
		source /opt/datadog-agent/venv/bin/activate && python /opt/datadog-agent/agent/dogstatsd.py
else
		exec "$@"
fi
