#!/bin/bash
#set -e

if [[ $DD_API_KEY ]]; then
  export API_KEY=${DD_API_KEY}
fi

if [[ $DD_API_KEY_FILE ]]; then
  export API_KEY=$(cat $DD_API_KEY_FILE)
fi

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /etc/dd-agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run the DogStatsD container"
	exit 1
fi

if [[ $DD_URL ]]; then
    sed -i -e 's@^.*dd_url:.*$@dd_url: '${DD_URL}'@' /etc/dd-agent/datadog.conf
fi

if [[ $DD_HOSTNAME ]]; then
    sed -i -r -e "s/^# ?hostname.*$/hostname: ${DD_HOSTNAME}/" /etc/dd-agent/datadog.conf
fi

# ensure that the trace-agent doesn't run unless instructed to
if [[ $DD_APM_ENABLED ]]; then
    export DD_APM_ENABLED=${DD_APM_ENABLED}
 else 
    # disable the agent when the env var is absent
    export DD_APM_ENABLED=false
 fi

if [[ -z $DD_HOSTNAME && $DD_APM_ENABLED ]]; then
        # When starting up the trace-agent without an explicit hostname
        # we need to ensure that the trace-agent will report as the same host as the
        # infrastructure agent.
        # To do this, we execute some of dd-agent's python code and expose the hostname
        # as an env var
        export DD_HOSTNAME=`PYTHONPATH=/opt/datadog-agent/agent /opt/datadog-agent/embedded/bin/python -c "from utils.hostname import get_hostname; print get_hostname()"`
fi

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

exec "$@"
