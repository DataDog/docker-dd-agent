#! /bin/sh
test $(/opt/datadog-agent/embedded/bin/python /opt/datadog-agent/bin/supervisorctl -c /etc/dd-agent/supervisor.conf status | awk '{print $2}' | egrep -v 'RUNNING|EXITED' | wc -l) = 0 || exit 1
