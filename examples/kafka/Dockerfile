# Example - Kafka
#
# Agent running a Kafka check

FROM datadog/docker-dd-agent

# Install Kafka check dependencies
RUN apt-get install openjdk-7-jre-headless python-setuptools -qq --no-install-recommends
RUN easy_install kazoo

# Add Kafka check configuration
ADD kafka.yaml /etc/dd-agent/conf.d/kafka.yaml
