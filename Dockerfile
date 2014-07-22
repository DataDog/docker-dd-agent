FROM debian:wheezy

MAINTAINER Benjamin Fernandes <benjamin@datadoghq.com>

ENV DOCKER_DD_AGENT yes

# Add datadog repository
RUN echo "deb http://apt.datadoghq.com/ stable main" > /etc/apt/sources.list.d/datadog.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52
RUN apt-get update

# Install the Agent
RUN apt-get install datadog-agent -qq --no-install-recommends

# Free space
RUN apt-get clean

# Configure the Agent
RUN mv /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf
# Listen to statsd from other containers
RUN sed -i -e"s/^.*non_local_traffic:.*$/non_local_traffic: yes/" /etc/dd-agent/datadog.conf
# Turn off syslog
RUN sed -i -e"s/^.*log_to_syslog:.*$/log_to_syslog: no/" /etc/dd-agent/datadog.conf
# Remove dd-agent user from supervisor configuration
RUN sed -i "/user=dd-agent/d" /etc/dd-agent/supervisor.conf

# Expose DogStatsD port
EXPOSE 8125/udp

ADD run-dd-agent.sh /usr/local/bin/run-dd-agent.sh
RUN chmod +x /usr/local/bin/run-dd-agent.sh


CMD ["/usr/local/bin/run-dd-agent.sh"]
