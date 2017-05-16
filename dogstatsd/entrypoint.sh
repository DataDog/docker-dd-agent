#!/bin/bash
#set -e

if [[ $DD_API_KEY ]]; then
  export API_KEY=${DD_API_KEY}
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

# ensure that the trace-agent doesn't run unless instructed to
export DD_APM_ENABLED=false
if [[ $DD_APM_ENABLED ]]; then
  export DD_APM_ENABLED=${DD_APM_ENABLED}
fi

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

exec "$@"
