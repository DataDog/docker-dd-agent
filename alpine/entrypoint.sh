#!/bin/sh
#set -e
set -x

##### Core config #####

if [[ $DD_API_KEY ]]; then
  export API_KEY=${DD_API_KEY}
fi

if [[ $DD_API_KEY_FILE ]]; then
  export API_KEY=$(cat $DD_API_KEY_FILE)
fi

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /opt/datadog-agent/agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run the Datadog Agent container"
	exit 1
fi

if [[ $DD_HOSTNAME ]]; then
	sed -i -r -e "s/^# ?hostname.*$/hostname: ${DD_HOSTNAME}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $DD_TAGS ]]; then
  export TAGS=${DD_TAGS}
fi

if [[ $EC2_TAGS ]]; then
	sed -i -e "s/^# collect_ec2_tags.*$/collect_ec2_tags: ${EC2_TAGS}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $TAGS ]]; then
	sed -i -r -e "s/^# ?tags:.*$/tags: ${TAGS}/" /opt/datadog-agent/agent/datadog.conf
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

if [[ $STATSD_METRIC_NAMESPACE ]]; then
    sed -i -e "s/^# statsd_metric_namespace:.*$/statsd_metric_namespace: ${STATSD_METRIC_NAMESPACE}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $USE_DOGSTATSD ]]; then
    sed -i -e "s/^.*use_dogstatsd:.*$/use_dogstatsd: ${USE_DOGSTATSD}/" /opt/datadog-agent/agent/datadog.conf
fi


##### Proxy config #####

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

##### Service discovery #####
EC2_HOST_IP=`curl --silent http://169.254.169.254/latest/meta-data/local-ipv4 --max-time 1`

if [[ $SD_BACKEND ]]; then
    sed -i -e "s/^# service_discovery_backend:.*$/service_discovery_backend: ${SD_BACKEND}/" /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_CONFIG_BACKEND ]]; then
    sed -i -e "s/^# sd_config_backend:.*$/sd_config_backend: ${SD_CONFIG_BACKEND}/" /opt/datadog-agent/agent/datadog.conf
    # If no SD_BACKEND_HOST value is defined AND running in EC2 and host ip is available
    if [[ -z $SD_BACKEND_HOST && -n $EC2_HOST_IP ]]; then
        export SD_BACKEND_HOST="$EC2_HOST_IP"
    fi
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

if [[ $SD_CONSUL_TOKEN ]]; then
    sed -i -e 's@^# consul_token:.*$@consul_token: '${SD_CONSUL_TOKEN}'@' /opt/datadog-agent/agent/datadog.conf
fi

if [[ $SD_JMX_ENABLE ]]; then
    sed -i -e "s/^.*sd_jmx_enable:.*$/sd_jmx_enable: ${SD_JMX_ENABLE}/" /opt/datadog-agent/agent/datadog.conf
fi

##### Integrations config #####

if [[ -n "${KUBERNETES}" || -n "${MESOS_MASTER}" || -n "${MESOS_SLAVE}" ]]; then
    # expose supervisord as a health check
    echo "
[inet_http_server]
port = 0.0.0.0:9001
" >> /opt/datadog-agent/agent/supervisor.conf
fi

if [[ $KUBERNETES ]]; then
    # enable kubernetes check
    cp /opt/datadog-agent/agent/conf.d/kubernetes.yaml.example /opt/datadog-agent/agent/conf.d/kubernetes.yaml

    # enable event collector
    # WARNING: to avoid duplicates, only one agent at a time across the entire cluster should have this feature enabled.
    if [[ $KUBERNETES_COLLECT_EVENTS ]]; then
        sed -i -e "s@# collect_events: false@ collect_events: true@" /opt/datadog-agent/agent/conf.d/kubernetes.yaml

        # enable the namespace regex
        if [[ $KUBERNETES_NAMESPACE_NAME_REGEX ]]; then
            sed -i -e "s@# namespace_name_regexp:@ namespace_name_regexp: ${KUBERNETES_NAMESPACE_NAME_REGEX}@" /opt/datadog-agent/agent/conf.d/kubernetes.yaml
        fi
    fi
fi

if [[ $MESOS_MASTER ]]; then
    cp /opt/datadog-agent/agent/conf.d/mesos_master.yaml.example /opt/datadog-agent/agent/conf.d/mesos_master.yaml
    cp /opt/datadog-agent/agent/conf.d/zk.yaml.example /opt/datadog-agent/agent/conf.d/zk.yaml

    sed -i -e "s/localhost/leader.mesos/" /opt/datadog-agent/agent/conf.d/mesos_master.yaml
    sed -i -e "s/localhost/leader.mesos/" /opt/datadog-agent/agent/conf.d/zk.yaml
fi

if [[ $MESOS_SLAVE ]]; then
    cp /opt/datadog-agent/agent/conf.d/mesos_slave.yaml.example /opt/datadog-agent/agent/conf.d/mesos_slave.yaml

    sed -i -e "s/localhost/$HOST/" /opt/datadog-agent/agent/conf.d/mesos_slave.yaml
fi

if [[ $MARATHON_URL ]]; then
    cp /opt/datadog-agent/agent/conf.d/marathon.yaml.example /opt/datadog-agent/agent/conf.d/marathon.yaml
    sed -i -e "s@# - url: \"https://server:port\"@- url: ${MARATHON_URL}@" /opt/datadog-agent/agent/conf.d/marathon.yaml
fi

find /conf.d -name '*.yaml' -exec cp --parents {} /opt/datadog-agent/agent \;

find /checks.d -name '*.py' -exec cp {} /opt/datadog-agent/agent/checks.d \;


##### Starting up #####

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

if [[ $DOGSTATSD_ONLY ]]; then
		source /opt/datadog-agent/venv/bin/activate && python /opt/datadog-agent/agent/dogstatsd.py
else
		exec "$@"
fi
