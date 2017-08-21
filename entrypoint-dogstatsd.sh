#!/bin/sh
#set -e

# When using venv, activate it 1st
if [ -n $DD_HOME ]; then
  if [ -f "${DD_HOME}/venv/bin/activate" ]; then
    source ${DD_HOME}/venv/bin/activate
  fi
fi

##### Core config #####
python /config_builder.py

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
