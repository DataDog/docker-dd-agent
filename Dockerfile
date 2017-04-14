FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT yes
ENV AGENT_VERSION 1:5.6.3-1

# Install the Agent
ADD https://1018-34269086-gh.circle-artifacts.com/0//home/ubuntu/docker-dd-agent-build-deb-x64/pkg/datadog-agent_5.9.0.git.101.017a444-1_amd64.deb /
RUN dpkg -i /datadog-agent_5.9.0.git.101.017a444-1_amd64.deb && rm /datadog-agent_5.9.0.git.101.017a444-1_amd64.deb

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

# Enable remote supervisor connections
COPY supervisor.conf /etc/dd-agent/supervisor.conf

# Add Docker check
COPY conf.d/docker_daemon.yaml /etc/dd-agent/conf.d/docker_daemon.yaml

# Add Kubernetes check
COPY conf.d/kubernetes.yaml /etc/dd-agent/conf.d/kubernetes.yaml

# Apply Docker backports
COPY docker.py /etc/dd-agent/checks.d/docker.py

COPY entrypoint.sh /entrypoint.sh

# Extra conf.d and checks.d
CMD mkdir -p /conf.d
CMD mkdir -p /checks.d
VOLUME ["/conf.d"]
VOLUME ["/checks.d"]

# Expose supervisor port
EXPOSE 9001/tcp

# Expose DogStatsD port
EXPOSE 8125/udp
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
