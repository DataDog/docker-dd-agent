FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT yes
ENV AGENT_VERSION 1:5.8.0-1

# Install the Agent + dnsutils
RUN echo "deb http://apt.datadoghq.com/ stable main" > /etc/apt/sources.list.d/datadog.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52 \
 && apt-get update \
 && apt-get install --no-install-recommends -y datadog-agent="${AGENT_VERSION}" dnsutils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure the Agent
# 1. Listen to statsd from other containers
# 2. Turn syslog off
# 3. Remove dd-agent user from supervisor configuration
# 4. Remove dd-agent user from init.d configuration
# 5. Fix permission on /etc/init.d/datadog-agent
# 6. Remove network check
# 7. Symlink Dogstatsd to allow standalone execution
RUN mv /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf \
 && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" /etc/dd-agent/datadog.conf \
 && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" /etc/dd-agent/datadog.conf \
 && sed -i "/user=dd-agent/d" /etc/dd-agent/supervisor.conf \
 && sed -i 's/AGENTUSER="dd-agent"/AGENTUSER="root"/g' /etc/init.d/datadog-agent \
 && chmod +x /etc/init.d/datadog-agent \
 && rm /etc/dd-agent/conf.d/network.yaml.default \
 && ln -s /opt/datadog-agent/agent/dogstatsd.py /usr/bin/dogstatsd

# Add Docker check
COPY conf.d/docker_daemon.yaml /etc/dd-agent/conf.d/docker_daemon.yaml

# Add Mesos master/slave check
COPY conf.d/mesos_master.yaml /etc/dd-agent/conf.d/mesos_master.yaml
COPY conf.d/mesos_slave.yaml /etc/dd-agent/conf.d/mesos_slave.yaml

# Add Marathon check
COPY conf.d/marathon.yaml /etc/dd-agent/conf.d/marathon.yaml

# Add Zookeeper check
COPY conf.d/zk.yaml /etc/dd-agent/conf.d/zk.yaml

# Extra conf.d and checks.d
VOLUME ["/conf.d"]
VOLUME ["/checks.d"]

COPY entrypoint.sh /entrypoint.sh

# Expose DogStatsD port and supervisord
EXPOSE 8125/udp 9001/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
