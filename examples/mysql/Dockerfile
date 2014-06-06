# Example - Simple
#
# Run a raw Agent, only reporting system metrics

FROM datadog/docker-dd-agent

# Set your API key
RUN sed -i -e"s/^.*api_key:.*$/api_key: EXAMPLE_API_KEY/" /etc/dd-agent/datadog.conf

# Install check dependencies
RUN apt-get install python-mysqldb -y

# Add MySQL check configuration
ADD mysql.yaml /etc/dd-agent/conf.d/mysql.yaml