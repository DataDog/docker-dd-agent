#!/bin/sh
#set -e

# When using venv, activate it 1st
if [ -n $DD_HOME ]; then
  if [ -f "${DD_HOME}/venv/bin/activate" ]; then
    source ${DD_HOME}/venv/bin/activate
  fi
fi

# Move the supervisord socket to /dev/shm to circumvent
# https://github.com/Supervisor/supervisor/issues/654
sed -i "s@/opt/datadog-agent/run/datadog-supervisor.sock@/dev/shm/datadog-supervisor.sock@" ${DD_ETC_ROOT}/supervisor.conf
# for datadog.conf
export DD_CONF_SUPERVISOR_SOCKET="/dev/shm/datadog-supervisor.sock"

##### Core config #####
python /config_builder.py

if [ $DD_LOGS_STDOUT ]; then
  export LOGS_STDOUT=$DD_LOGS_STDOUT
fi

if [ "$LOGS_STDOUT" = "yes" ]; then
  sed -i -e "/^.*_logfile.*$/d" ${DD_ETC_ROOT}/supervisor.conf
  sed -i -e '/^.*\[program:.*\].*$/a stdout_logfile=\/dev\/stdout\
stdout_logfile_maxbytes=0\
stderr_logfile=\/dev\/stderr\
stderr_logfile_maxbytes=0' ${DD_ETC_ROOT}/supervisor.conf
fi

# ensure that the trace-agent doesn't run unless instructed to
export DD_APM_ENABLED=${DD_APM_ENABLED:-false}

##### Starting up #####

if [ -z $DD_HOSTNAME ] && [ $DD_APM_ENABLED ]; then
  # When starting up the trace-agent without an explicit hostname
  # we need to ensure that the trace-agent will report as the same host as the
  # infrastructure agent.
  # To do this, we execute some of dd-agent's python code and expose the hostname
  # as an env var
  export DD_HOSTNAME=`python -c "from utils.hostname import get_hostname; print get_hostname()"`
fi

exec "$@"
