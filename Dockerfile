FROM datadog/docker-dd-agent:latest
MAINTAINER Datadog <package@datadoghq.com>

# Install patch (silent)
RUN apt-get -qq update \
 && apt-get -qq install --no-install-recommends -y patch \
 && apt-get -qq clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Apply listed patches
ADD backport.py patches /
RUN /opt/datadog-agent/embedded/bin/python /backport.py /patches > /diff && \
    patch -ubN -p0 -d /opt/datadog-agent/ < /diff && \
    rm /backport.py /diff  # /patches kept on purpose