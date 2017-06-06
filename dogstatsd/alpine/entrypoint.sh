#!/bin/sh
#set -e

if [[ $DD_API_KEY ]]; then
  export API_KEY=${DD_API_KEY}
fi

if [[ $DD_API_KEY_FILE ]]; then
  export API_KEY=$(cat $DD_API_KEY_FILE)
fi

if [[ $API_KEY ]]; then
    sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" $DD_HOME/agent/datadog.conf
else
    echo "You must set API_KEY environment variable to run the DogStatsD container"
    exit 1
fi

if [[ $DD_URL ]]; then
    sed -i -e 's@^.*dd_url:.*$@dd_url: '${DD_URL}'@' $DD_HOME/agent/datadog.conf
fi

export PATH="$DD_HOME/venv/bin:$DD_HOME/bin:$PATH"

exec "$@"
