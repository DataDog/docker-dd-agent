# Example - Simple
#
# Run a raw Agent, only reporting system metrics

FROM datadog/docker-dd-agent

# Install check dependencies
RUN apt-get install python-mysqldb -y

# Add MySQL check configuration
ADD mysql.yaml /etc/dd-agent/conf.d/mysql.yaml