# Example - Kafka
#
# Agent running a Kafka check

FROM datadog/docker-dd-agent

# Set your API key
RUN sed -i -e"s/^.*api_key:.*$/api_key: EXAMPLE_API_KEY/" /etc/dd-agent/datadog.conf

# Install Kafka check dependencies
RUN apt-get install openjdk-7-jre-headless python-setuptools -y
RUN easy_install kazoo

# Add Kafka check configuration
ADD kafka.yaml /etc/dd-agent/conf.d/kafka.yaml
