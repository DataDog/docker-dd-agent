FROM alpine:3.4

MAINTAINER Datadog <package@datadoghq.com>

ENV DD_HOME=/opt/datadog-agent \
    DOCKER_DD_AGENT=yes \
    AGENT_VERSION=5.8.5 \
    # prevent the agent from being started after install
    DD_START_AGENT=0

# Add Docker check
COPY conf.d/docker_daemon.yaml "$DD_HOME/agent/conf.d/docker_daemon.yaml"

# Add install and config files
ADD https://raw.githubusercontent.com/DataDog/dd-agent/$AGENT_VERSION/packaging/datadog-agent/source/setup_agent.sh /tmp/setup_agent.sh
COPY entrypoint.sh /entrypoint.sh

# Expose supervisor and DogStatsD port
EXPOSE 9001/tcp 8125/udp

# Install minimal dependencies
RUN apk add -qU --no-cache curl-dev python-dev tar sysstat

# Install build dependencies
RUN apk add -qU --no-cache -t .build-deps curl gcc musl-dev pgcluster-dev linux-headers \
    # Install the agent
    && sh /tmp/setup_agent.sh \
    # Clean build dependencies
    && apk del -q .build-deps

# Configure the Agent
# 1. Listen to statsd from other containers
# 2. Turn syslog off
# 3. Remove dd-agent user from supervisor configuration
# 4. Remove network check
# 6. Remove setup script
RUN cp "$DD_HOME/agent/datadog.conf.example" "$DD_HOME/agent/datadog.conf" \
  && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" "$DD_HOME/agent/datadog.conf" \
  && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" "$DD_HOME/agent/datadog.conf" \
  && sed -i "/user=dd-agent/d" "$DD_HOME/agent/supervisor.conf" \
  && rm "$DD_HOME/agent/conf.d/network.yaml.default" \
  && rm /tmp/setup_agent.sh

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR "$DD_HOME"
CMD source venv/bin/activate && supervisord -c agent/supervisor.conf
