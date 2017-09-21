#! /bin/sh
test $(/opt/datadog-agent/venv/bin/python /opt/datadog-agent/venv/bin/supervisorctl -c /opt/datadog-agent/agent/supervisor.conf status | awk '{print $2}' | egrep -v 'RUNNING|EXITED' | wc -l) = 0 || exit 1
