FROM debian:wheezy

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT yes

# Install the Agent
RUN echo "deb http://apt.datadoghq.com/ stable main" > /etc/apt/sources.list.d/datadog.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52 \
 && apt-get update \
 && apt-get install -y datadog-agent

# Configure the Agent
# 1. Listen to statsd from other containers
# 2. Turn syslog off
# 3. Remove dd-agent user from supervisor configuration
# 4. Remove network check
RUN mv /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf \
 && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" /etc/dd-agent/datadog.conf \
 && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" /etc/dd-agent/datadog.conf \
 && sed -i "/user=dd-agent/d" /etc/dd-agent/supervisor.conf \
 && rm /etc/dd-agent/conf.d/network.yaml

# Add Docker check
COPY conf.d/docker.yaml /etc/dd-agent/conf.d/docker.yaml

# Hotfix: Fix Docker 1.2 compatibility until next Agent release
RUN sed -i -e"s/self.should_get_size = True/self.should_get_size = False/" /opt/datadog-agent/agent/checks.d/docker.py
COPY entrypoint.sh /entrypoint.sh

# Expose DogStatsD port
EXPOSE 8125/udp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
