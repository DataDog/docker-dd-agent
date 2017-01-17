FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT=yes \
    AGENT_VERSION=1:5.10.1-1

# Install the Agent
ADD https://1581-34269086-gh.circle-artifacts.com/0/home/ubuntu/docker-dd-agent-build-deb-x64/pkg/datadog-agent_5.11.0.git.171.a23655a-1_amd64.deb /
RUN dpkg -i /datadog-agent_5.11.0.git.171.a23655a-1_amd64.deb && rm /datadog-agent_5.11.0.git.171.a23655a-1_amd64.deb

RUN apt-get update && apt-get install --no-install-recommends -y vim curl jq

# Configure the Agent
# 1. Listen to statsd from other containers
# 2. Turn syslog off
# 3. Remove dd-agent user from supervisor configuration
# 4. Remove dd-agent user from init.d configuration
# 5. Fix permission on /etc/init.d/datadog-agent
# 6. Remove network check
RUN mv /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf \
 && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" /etc/dd-agent/datadog.conf \
 && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" /etc/dd-agent/datadog.conf \
 && sed -i "/user=dd-agent/d" /etc/dd-agent/supervisor.conf \
 && sed -i 's/AGENTUSER="dd-agent"/AGENTUSER="root"/g' /etc/init.d/datadog-agent \
 && chmod +x /etc/init.d/datadog-agent \
 && rm /etc/dd-agent/conf.d/network.yaml.default

# Add Docker check
COPY conf.d/docker_daemon.yaml /etc/dd-agent/conf.d/docker_daemon.yaml

COPY entrypoint.sh /entrypoint.sh

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

# Expose DogStatsD and supervisord ports
EXPOSE 8125/udp 9001/tcp

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD test $(/opt/datadog-agent/embedded/bin/python /opt/datadog-agent/bin/supervisorctl \
      -c /etc/dd-agent/supervisor.conf status | awk '{print $2}' | egrep -v 'RUNNING|EXITED' | wc -l) \
      -eq 0 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
