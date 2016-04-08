FROM alpine:3.3

MAINTAINER Datadog <package@datadoghq.com>

ENV DD_HOME /opt/datadog-agent
ENV DOCKER_DD_AGENT yes

# Add Docker check
COPY conf.d/docker_daemon.yaml "$DD_HOME/agent/conf.d/docker_daemon.yaml"

# Add install and config files
COPY setup_agent.sh /setup_agent.sh
COPY entrypoint.sh /entrypoint.sh

# Install minimal dependencies
RUN apk add --update curl-dev python-dev tar sysstat

# Install optional dependencies
RUN apk add gcc musl-dev pgcluster-dev linux-headers

# Expose supervisor port
EXPOSE 9001/tcp

# Expose DogStatsD port
EXPOSE 8125/udp

# Install the agent
RUN sh /setup_agent.sh

# Configure the Agent
# 1. Listen to statsd from other containers
# 2. Turn syslog off
# 3. Remove dd-agent user from supervisor configuration
# 6. Remove network check
# 7. Symlink Dogstatsd to allow standalone execution
RUN cp "$DD_HOME/agent/datadog.conf.example" "$DD_HOME/agent/datadog.conf" \
  && sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" "$DD_HOME/agent/datadog.conf" \
  && sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" "$DD_HOME/agent/datadog.conf" \
  && sed -i "/user=dd-agent/d" "$DD_HOME/agent/supervisor.conf" \
  && rm "$DD_HOME/agent/conf.d/network.yaml.default" \
  && ln -s /opt/datadog-agent/agent/dogstatsd.py /usr/bin/dogstatsd

# Extra conf.d and checks.d
VOLUME ["/conf.d"]
VOLUME ["/checks.d"]

ENTRYPOINT ["/entrypoint.sh"]

CMD cd "$DD_HOME" && source venv/bin/activate && supervisord -c agent/supervisor.conf
