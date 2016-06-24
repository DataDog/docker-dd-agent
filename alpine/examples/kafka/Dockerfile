# Example - Kafka
#
# Agent running a Kafka check

FROM datadog/docker-dd-agent

# Install JMXFetch dependencies
RUN apk add --update openjdk7-jre

# Add Kafka check configuration
ADD kafka.yaml /etc/dd-agent/conf.d/kafka.yaml
