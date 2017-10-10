FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT=yes \
    AGENT_VERSION=1:5.17.3~logsbeta.2-1 \
    DD_ETC_ROOT=/etc/dd-agent \
    PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:${PATH}" \
    PYTHONPATH=/opt/datadog-agent/agent \
    DD_CONF_LOG_TO_SYSLOG=no \
    NON_LOCAL_TRAFFIC=yes \
    DD_SUPERVISOR_DELETE_USER=yes

# Install the Agent
RUN sh -c "echo 'deb http://apt.datad0g.com/ beta main' > /etc/apt/sources.list.d/datadog.list"
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52
RUN apt-get update
RUN apt-cache policy datadog-agent | grep logs
RUN apt-get install datadog-agent=1:5.17.3~logsbeta.2-1 -y
RUN apt-get install -y ca-certificates

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

# Add Logs-Agent Configs and Docker check configs
ADD conf.d/* ${DD_ETC_ROOT}/conf.d/
# Add install and config files
COPY entrypoint.sh /entrypoint.sh
COPY config_builder.py /config_builder.py

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

# Expose DogStatsD and trace-agent ports
EXPOSE 8125/udp 8126/tcp 10518/udp

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD ./probe.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
