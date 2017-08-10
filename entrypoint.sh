#!/bin/bash
#set -e


##### Core config #####
/opt/datadog-agent/embedded/bin/python /config_builder.py

if [[ "${DD_SUPERVISOR_DELETE_USER}" == "yes" ]]; then
  sed -i "/user=dd-agent/d" /etc/dd-agent/supervisor.conf
fi

if [[ $DD_LOGS_STDOUT ]]; then
  export LOGS_STDOUT=$DD_LOGS_STDOUT
fi

if [[ "$LOGS_STDOUT" == "yes" ]]; then
  sed -i -e "/^.*_logfile.*$/d" /etc/dd-agent/supervisor.conf
  sed -i -e "/^.*\[program:.*\].*$/a stdout_logfile=\/dev\/stdout\nstdout_logfile_maxbytes=0\nstderr_logfile=\/dev\/stderr\nstderr_logfile_maxbytes=0" /etc/dd-agent/supervisor.conf
fi

##### Integrations config #####

if [[ $KUBERNETES || $MESOS_MASTER || $MESOS_SLAVE ]]; then
  # expose supervisord as a health check
  echo "
[inet_http_server]
port = 0.0.0.0:9001
" >> /etc/dd-agent/supervisor.conf
fi

if [[ $KUBERNETES ]]; then
  # enable kubernetes check
  cp /etc/dd-agent/conf.d/kubernetes.yaml.example /etc/dd-agent/conf.d/kubernetes.yaml

  # allows to disable kube_service tagging if needed (big clusters)
  if [[ $KUBERNETES_COLLECT_SERVICE_TAGS ]]; then
    sed -i -e 's@# collect_service_tags:.*$@ collect_service_tags: '${KUBERNETES_COLLECT_SERVICE_TAGS}'@' /etc/dd-agent/conf.d/kubernetes.yaml
  fi

  # enable event collector
  # WARNING: to avoid duplicates, only one agent at a time across the entire cluster should have this feature enabled.
  if [[ $KUBERNETES_COLLECT_EVENTS ]]; then
    sed -i -e "s@# collect_events: false@ collect_events: true@" /etc/dd-agent/conf.d/kubernetes.yaml

    # enable the namespace regex
    if [[ $KUBERNETES_NAMESPACE_NAME_REGEX ]]; then
      sed -i -e "s@# namespace_name_regexp:@ namespace_name_regexp: ${KUBERNETES_NAMESPACE_NAME_REGEX}@" /etc/dd-agent/conf.d/kubernetes.yaml
    fi
  fi

fi

if [[ $MESOS_MASTER ]]; then
  cp /etc/dd-agent/conf.d/mesos_master.yaml.example /etc/dd-agent/conf.d/mesos_master.yaml
  cp /etc/dd-agent/conf.d/zk.yaml.example /etc/dd-agent/conf.d/zk.yaml

  sed -i -e "s/localhost/leader.mesos/" /etc/dd-agent/conf.d/mesos_master.yaml
  sed -i -e "s/localhost/leader.mesos/" /etc/dd-agent/conf.d/zk.yaml
fi

if [[ $MESOS_SLAVE ]]; then
  cp /etc/dd-agent/conf.d/mesos_slave.yaml.example /etc/dd-agent/conf.d/mesos_slave.yaml

  sed -i -e "s/localhost/$HOST/" /etc/dd-agent/conf.d/mesos_slave.yaml
fi

if [[ $MARATHON_URL ]]; then
  cp /etc/dd-agent/conf.d/marathon.yaml.example /etc/dd-agent/conf.d/marathon.yaml
  sed -i -e "s@# - url: \"https://server:port\"@- url: ${MARATHON_URL}@" /etc/dd-agent/conf.d/marathon.yaml
fi

find /conf.d -name '*.yaml' -exec cp --parents {} /etc/dd-agent \;

find /checks.d -name '*.py' -exec cp --parents {} /etc/dd-agent \;


##### Starting up #####

if [[ -z $DD_HOSTNAME && $DD_APM_ENABLED ]]; then
  # When starting up the trace-agent without an explicit hostname
  # we need to ensure that the trace-agent will report as the same host as the
  # infrastructure agent.
  # To do this, we execute some of dd-agent's python code and expose the hostname
  # as an env var
  export DD_HOSTNAME=`PYTHONPATH=/opt/datadog-agent/agent /opt/datadog-agent/embedded/bin/python -c "from utils.hostname import get_hostname; print get_hostname()"`
fi

if [[ $DOGSTATSD_ONLY ]]; then
  echo "[WARNING] This option is deprecated as of agent 5.8.0, it will be removed in the next few versions. Please use the dogstatsd image instead."
  PYTHONPATH=/opt/datadog-agent/agent /opt/datadog-agent/embedded/bin/python /opt/datadog-agent/agent/dogstatsd.py
else
  exec "$@"
fi
