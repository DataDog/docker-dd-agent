# Example - Kafka
#
# Agent running a Kafka check

FROM datadog/docker-dd-agent

# Install JMXFetch dependencies
RUN apt-get update -qq && apt-get install openjdk-7-jre-headless -y -qq --no-install-recommends

# Add Kafka check configuration
ADD kafka.yaml /etc/dd-agent/conf.d/kafka.yaml

