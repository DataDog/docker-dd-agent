# Example - Complex
#
# Agent running with a more complex configuration

FROM datadog/docker-dd-agent

# Set your API key
RUN sed -i -e"s/^.*api_key:.*$/api_key: YOUR_API_KEY/" /etc/dd-agent/datadog.conf

# Add Apache check configuration
ADD datadog.conf /etc/dd-agent/datadog.conf
ADD network.yaml /etc/dd-agent/conf.d/network.yaml
