FROM alpine:3.4

MAINTAINER Datadog <package@datadoghq.com>

ENV DD_HOME=/opt/datadog-agent \
    DOCKER_DD_AGENT=yes \
    # prevent the agent from being started after install
    DD_START_AGENT=0 \
    AGENT_VERSION=5.14.1

# Add install and config files
ADD https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/setup_agent.sh /tmp/setup_agent.sh
COPY entrypoint.sh supervisor.conf /

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
# 3. Use custom supervisor.conf
# 4. Clean up the install script
RUN mv $DD_HOME/agent/datadog.conf.example $DD_HOME/agent/datadog.conf \
 && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" $DD_HOME/agent/datadog.conf \
 && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" $DD_HOME/agent/datadog.conf \
 && mv /supervisor.conf $DD_HOME/agent/supervisor.conf \
 && rm /tmp/setup_agent.sh

# Set proper permissions to allow running as a non-root user
RUN chmod -R g+wx $DD_HOME \
  && chmod g+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

USER 1001

CMD supervisord -n -c $DD_HOME/agent/supervisor.conf
