#!/bin/sh
#set -e

# Debian images
if [ -f /etc/debian_version ]
then
  apt-get update > /dev/null
  apt-get install --no-install-recommends -y vim curl less  > /dev/null
  # Allow to skip -c argument to supervisorctl
  ln -s /etc/dd-agent/supervisor.conf /etc/supervisord.conf

  echo '#!/bin/sh' > /usr/local/bin/restart-collector
  echo '/opt/datadog-agent/bin/supervisorctl -c /etc/dd-agent/supervisor.conf restart datadog-agent:collector' >> /usr/local/bin/restart-collector
  chmod +x /usr/local/bin/restart-collector
fi

# Alpine images
if [ -f /etc/alpine-release ]
then
  apk update > /dev/null
  apk add bash curl vim less  > /dev/null

  echo '#!/bin/sh' > /usr/local/bin/restart-collector
  echo '/opt/datadog-agent/venv/bin/supervisorctl -c /opt/datadog-agent/agent/supervisor.conf restart datadog-agent:collector' >> /usr/local/bin/restart-collector
  chmod +x /usr/local/bin/restart-collector
fi
