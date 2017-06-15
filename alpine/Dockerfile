FROM alpine:3.4

MAINTAINER Datadog <package@datadoghq.com>

ENV DD_HOME=/opt/datadog-agent \
    # prevent the agent from being started after install
    DD_START_AGENT=0 \
    DOCKER_DD_AGENT=yes \
    PYCURL_SSL_LIBRARY=openssl \
    AGENT_VERSION=5.14.1

# Add Docker check
COPY conf.d/docker_daemon.yaml "$DD_HOME/agent/conf.d/docker_daemon.yaml"

# Add install and config files
ADD https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/setup_agent.sh /tmp/setup_agent.sh
COPY entrypoint.sh /entrypoint.sh

# Expose supervisor and DogStatsD port
EXPOSE 9001/tcp 8125/udp

# Install minimal dependencies
RUN apk add -qU --no-cache coreutils curl curl-dev python-dev tar sysstat tini

# Install build dependencies
RUN apk add -qU --no-cache -t .build-deps gcc musl-dev pgcluster-dev linux-headers \
    # Install the agent
    && sh /tmp/setup_agent.sh \
    # Clean build dependencies
    && apk del -q .build-deps

# Configure the Agent
# 1. Listen to statsd from other containers
# 2. Turn syslog off
# 3. Remove dd-agent user from supervisor configuration
# 4. Remove setup script
RUN cp "$DD_HOME/agent/datadog.conf.example" "$DD_HOME/agent/datadog.conf" \
  && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" "$DD_HOME/agent/datadog.conf" \
  && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" "$DD_HOME/agent/datadog.conf" \
  && sed -i "/user=dd-agent/d" "$DD_HOME/agent/supervisor.conf" \
  && rm "$DD_HOME/agent/conf.d/network.yaml.default" \
  || rm /tmp/setup_agent.sh

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD test $($DD_HOME/venv/bin/python $DD_HOME/venv/bin/supervisorctl \
      -c $DD_HOME/agent/supervisor.conf status | awk '{print $2}' | egrep -v 'RUNNING|EXITED' | wc -l) \
      -eq 0 || exit 1

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]

WORKDIR "$DD_HOME"
CMD source venv/bin/activate && supervisord -c agent/supervisor.conf
