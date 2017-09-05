FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT=yes \
    AGENT_VERSION=1:5.17.0-1 \
    DD_ETC_ROOT=/etc/dd-agent \
    PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:${PATH}" \
    PYTHONPATH=/opt/datadog-agent/agent \
    DD_CONF_LOG_TO_SYSLOG=no \
    NON_LOCAL_TRAFFIC=yes \
    DD_SUPERVISOR_DELETE_USER=yes

# Install the Agent
ADD https://2135-34269086-gh.circle-artifacts.com/0/home/ubuntu/docker-dd-agent-build-deb-x64/pkg/datadog-agent_5.18.0.git.8.503d122-1_amd64.deb /
RUN dpkg -i /datadog-agent_5.18.0.git.8.503d122-1_amd64.deb && rm /datadog-agent_5.18.0.git.8.503d122-1_amd64.deb

# Configure the Agent
# 1. Remove dd-agent user from init.d configuration
# 2. Fix permission on /etc/init.d/datadog-agent
RUN mv ${DD_ETC_ROOT}/datadog.conf.example ${DD_ETC_ROOT}/datadog.conf \
 && sed -i 's/AGENTUSER="dd-agent"/AGENTUSER="root"/g' /etc/init.d/datadog-agent \
 && rm -f ${DD_ETC_ROOT}/conf.d/network.yaml.default \
 && chmod +x /etc/init.d/datadog-agent

# Add Docker check
COPY conf.d/docker_daemon.yaml ${DD_ETC_ROOT}/conf.d/docker_daemon.yaml
# Add install and config files
COPY entrypoint.sh /entrypoint.sh
COPY config_builder.py /config_builder.py

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

# Expose DogStatsD, supervisord and trace-agent ports
EXPOSE 8125/udp 9001/tcp 8126/tcp

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD test $(/opt/datadog-agent/embedded/bin/python /opt/datadog-agent/bin/supervisorctl \
      -c /etc/dd-agent/supervisor.conf status | awk '{print $2}' | egrep -v 'RUNNING|EXITED' | wc -l) \
      -eq 0 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
