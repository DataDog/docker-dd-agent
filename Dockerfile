FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT=yes \
    AGENT_VERSION=1:5.18.1-1 \
    DD_ETC_ROOT=/etc/dd-agent \
    PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:${PATH}" \
    PYTHONPATH=/opt/datadog-agent/agent \
    DD_CONF_LOG_TO_SYSLOG=no \
    NON_LOCAL_TRAFFIC=yes \
    DD_SUPERVISOR_DELETE_USER=yes

# Install the Agent
RUN apt-get update \
 && apt-get install --no-install-recommends -y apt-transport-https ca-certificates \
 && echo "deb https://apt.datad0g.com/ beta main" > /etc/apt/sources.list.d/datadog.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52 24BEB436F432F6E0 \
 && apt-get update \
 && apt-get install --no-install-recommends -y datadog-agent=1:5.22.0~rc.1-1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add healthcheck script
COPY probe.sh /probe.sh

# Configure the Agent
# 1. Remove dd-agent user from init.d configuration
# 2. Fix permission on /etc/init.d/datadog-agent
# 3. Make healthcheck script executable
RUN mv ${DD_ETC_ROOT}/datadog.conf.example ${DD_ETC_ROOT}/datadog.conf \
 && sed -i 's/AGENTUSER="dd-agent"/AGENTUSER="root"/g' /etc/init.d/datadog-agent \
 && rm -f ${DD_ETC_ROOT}/conf.d/network.yaml.default \
 && chmod +x /etc/init.d/datadog-agent \
 && chmod +x /probe.sh

# Add Docker check
COPY conf.d/docker_daemon.yaml ${DD_ETC_ROOT}/conf.d/docker_daemon.yaml
# Add install and config files
COPY entrypoint.sh /entrypoint.sh
COPY config_builder.py /config_builder.py

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

# Expose DogStatsD and trace-agent ports
EXPOSE 8125/udp 8126/tcp

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD ./probe.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
