# Example - Apache
#
# Agent running an Apache check

FROM datadog/docker-dd-agent

# Set your API key
RUN sed -i -e"s/^.*api_key:.*$/api_key: EXAMPLE_API_KEY/" /etc/dd-agent/datadog.conf

# Add Apache check configuration
ADD apache.yaml /etc/dd-agent/conf.d/apache.yaml
