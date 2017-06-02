# Datadog Agent Dockerfile

This repository is meant to build the base image for a Datadog Agent container. You will have to use the resulting image to configure and run the Agent.


## Quick Start

The default image is ready-to-go. You just need to set your API_KEY in the environment.

```
docker run -d --name dd-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
  -e API_KEY={your_api_key_here} \
  -e SD_BACKEND=docker \
  datadog/docker-dd-agent
```

If you are running on Amazon Linux, use the following instead:

```
docker run -d --name dd-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /cgroup/:/host/sys/fs/cgroup:ro \
  -e API_KEY={your_api_key_here} \
  -e SD_BACKEND=docker \
  datadog/docker-dd-agent
```


## Configuration


### Hostname

By default the agent container will use the `Name` field found in the `docker info` command from the host as a hostname. To change this behavior you can update the `hostname` field in `/etc/dd-agent/datadog.conf`. The easiest way for this is to use the `DD_HOSTNAME` environment variable (see below).


### CGroups

For the Docker check to succeed, memory management by cgroup must be enabled on the host as explained in the [debian wiki](https://wiki.debian.org/LXC#Preparing_the_host_system_for_running_LXC).
On Debian Jessie or later for example you will need to add `cgroup_enable=memory swapaccount=1` to your boot options, otherwise the agent won't be able to recognize your system. See [this thread](https://askubuntu.com/questions/19486/how-do-i-add-a-kernel-boot-parameter/19487#19487) for details.


### Service discovery

The commands we suggest in _Quick Start_ start service discovery in auto config mode. It means the agent will try and detect containers running [some images](https://github.com/DataDog/dd-agent/tree/5.11.2/conf.d/auto_conf) for which we provide a default check that works most of the time.

If you want to disable it, simply remove the `SD_BACKEND` environment variable.

If you want to learn more about it and how to configure it, head to the [service discovery guide](https://docs.datadoghq.com/guides/servicediscovery/).


### Environment variables

Some configuration parameters can be changed with environment variables:

* `DD_HOSTNAME` set the hostname (write it in `datadog.conf`)
* `TAGS` set host tags. Add `-e TAGS=simple-tag-0,tag-key-1:tag-value-1` to use [simple-tag-0, tag-key-1:tag-value-1] as host tags.
* `EC2_TAGS` set EC2 host tags. Add `-e EC2_TAGS=yes` to use EC2 custom host tags. Requires an [IAM role](https://github.com/DataDog/dd-agent/wiki/Capturing-EC2-tags-at-startup) associated with the instance.
* `LOG_LEVEL` set logging verbosity (CRITICAL, ERROR, WARNING, INFO, DEBUG). Add `-e LOG_LEVEL=DEBUG` to turn logs to debug mode.
* `PROXY_HOST`, `PROXY_PORT`, `PROXY_USER` and `PROXY_PASSWORD` set the proxy configuration.
* `DD_URL` set the Datadog intake server to send Agent data to (used when [using an agent as a proxy](https://github.com/DataDog/dd-agent/wiki/Proxy-Configuration#using-the-agent-as-a-proxy) )
* `NON_LOCAL_TRAFFIC` tells the image to set the `non_local_traffic: true` option, which enables statsd reporting from any external ip. You may find this useful to report metrics from your other containers. See [network configuration](https://github.com/DataDog/dd-agent/wiki/Network-Traffic-and-Proxy-Configuration) for more details.
* ~~`DOGSTATSD_ONLY` tell the image to only start a standalone dogstatsd instance.~~ **[deprecated]: please use [the dogstatsd-only image](#standalone-dogstatsd)**
* `SD_BACKEND`, `SD_CONFIG_BACKEND`, `SD_BACKEND_HOST`, `SD_BACKEND_PORT`, `SD_TEMPLATE_DIR` and `SD_CONSUL_TOKEN` configure service discovery:

   - `SD_BACKEND` can only be set to `docker` for now, since service discovery works only with docker containers.
   - `SD_CONFIG_BACKEND` can be set to `etcd` or `consul` which are the two configuration stores we support at the moment.
   - `SD_BACKEND_HOST` and `SD_BACKEND_PORT` are used to configure the connection to the configuration store, and `SD_TEMPLATE_DIR` to specify the path where the check configuration templates are stored.
   - `SD_CONSUL_TOKEN` is used to provide an authentication token for the agent to connect to Consul if required.
   - `SD_JMX_ENABLE` can be set to `yes` to enble JMX service discovery
* `DD_APM_ENABLED` run the trace-agent along with the infrastructure agent, allowing the container to accept traces on 8126/tcp (**This option is NOT available on Alpine Images**)

**Note:** it is possible to use `DD_TAGS` instead of `TAGS`, `DD_LOG_LEVEL` instead of `LOG_LEVEL` and `DD_API_KEY` instead of `API_KEY`, these variables have the same impact.


### Enabling integrations

#### Environment variables

It is possible to enable some checks through the environment:

* `KUBERNETES` enables the kubernetes check if set (`KUBERNETES=yes` works). `KUBERNETES_COLLECT_EVENTS` enables event collection from the kubernetes API, given that `KUBERNETES` is also set. **Note:** only one agent should have `KUBERNETES_COLLECT_EVENTS` set per cluster.
* the kubelet API endpoint is assumed to be the default route of the container, you can override the kubelet API endpoint by specifying `KUBERNETES_KUBELET_HOST` (eg. when using CNI networking, the kubelet API may not listen on the default route address)
* `MESOS_MASTER` and `MESOS_SLAVE` respectively enable the mesos master and mesos slave checks if set (`MESOS_MASTER=yes` works).
* `MARATHON_URL` if set will be used to enable the Marathon check that will query the URL passed in this variable for metrics. It can usually be set to `http://leader.mesos:8080`.

#### Service discovery

Another way to enable checks is through service discovery. This is particularly useful in dynamic environments like Kubernetes, Amazon ECS or Docker Swarm. More details about this feature can be found [in the doc](https://docs.datadoghq.com/guides/servicediscovery/).

#### Configuration files

You can also mount YAML configuration files in the `/conf.d` folder, they will automatically be copied to `/etc/dd-agent/conf.d/` when the container starts.  The same can be done for the `/checks.d` folder. Any Python files in the `/checks.d` folder will automatically be copied to `/etc/dd-agent/checks.d/` when the container starts.

1. Create a configuration folder on the host and write your YAML files in it.  The examples below can be used for the `/checks.d` folder as well.

    ```
    mkdir /opt/dd-agent-conf.d
    touch /opt/dd-agent-conf.d/nginx.yaml
    ```

2. When creating the container, mount this new folder to `/conf.d`.
    ```
    docker run -d --name dd-agent \
      -v /var/run/docker.sock:/var/run/docker.sock:ro \
      -v /proc/:/host/proc/:ro \
      -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
      -v /opt/dd-agent-conf.d:/conf.d:ro \
      -e API_KEY={your_api_key_here} \
      datadog/docker-dd-agent
    ```

    _The important part here is `-v /opt/dd-agent-conf.d:/conf.d:ro`_

Now when the container starts, all files in `/opt/dd-agent-conf.d` with a `.yaml` extension will be copied to `/etc/dd-agent/conf.d/`. Please note that to add new files you will need to restart the container.


## DogStatsD


### Standalone DogStatsD

The default images run a dogstatsd server as well as the agent. If you want to run DogStatsD only, we provide [standalone images](https://github.com/DataDog/docker-dd-agent/tree/master/dogstatsd) for it. They are identified by the `dogstatsd` keyword in their docker tag (eg: `11.3.585-dogstatsd`, `11.3.585-dogstatsd-alpine`).

These separate images have the advantage of running DogStatsD server as a non-root user which is useful for platforms like OpenShift. They also don't need shared volumes from the host (`/proc`, `/sys/fs` and the Docker socket) like the complete agent image.

**Note**: These images run DogStatsD only. In the agent, tags are collected from the configuration file and from labels by the collector which is not running here. Thus those tags will not be associated with any metrics and events processed by this container.

**Note**: Optionally, the standalone DogStatsD image can also run the the trace-agent process. Pass `-e DD_APM_ENABLED=true` to your `docker run` command to activate the trace-agent and allow your container to receive traces from Datadog's APM integrations.

### DogStatsD from the host

DogStatsD can be available on port 8125 from anywhere by adding the option `-p 8125:8125/udp` to the `docker run` command.

To make it available from your host only, use `-p 127.0.0.1:8125:8125/udp` instead.

### Disable dogstatsd

DogStatsd can be disabled by setting `USE_DOGSTATSD` to `no`

### DogStatsD from other containers

#### Using Docker links

To send data to DogStatsD from other containers, add a `--link dogstatsd:dogstatsd` option to your run command.

For example, run a container `my_container` with the image `my_image`.

```
docker run  --name my_container           \
            --all_your_flags              \
            --link dogstatsd:dogstatsd    \
            my_image
```

DogStatsD address and port will be available in `my_container`'s environment variables `DOGSTATSD_PORT_8125_UDP_ADDR` and `DOGSTATSD_PORT_8125_UDP_PORT`.

#### Using Docker host IP

Since the Agent container port 8125 should be linked to the host directly, you can connect to DogStatsD through the host. Usually the IP address of the host in a Docker container can be determined by looking at the address of the default route of this container with `ip route` for example. You can then configure your DogStatsD client to connect to `172.17.42.1:8125` for example.


## Tracing + APM

Enable the [datadog-trace-agent](https://github.com/DataDog/datadog-trace-agent) in the `docker-dd-agent` container by passing
`DD_APM_ENABLED=true` as an environment variable

**Note: APM is NOT available on Alpine Images**

### Tracing from the host

Tracing can be available on port 8126/tcp from anywhere by adding the options `-p 8126:8126/tcp` to the `docker run` command

To make it available from your host only, use `-p 127.0.0.1:8126:8126/tcp` instead.

For example, the following command will allow the agent to receive traces from anywhere

```
docker run -d --name dd-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
  -e API_KEY={your_api_key_here} \
  -e DD_APM_ENABLED=true \
  -p 8126:8126/tcp \
  datadog/docker-dd-agent
```

Previous instructions required binding to port 7777.
This is a legacy port used by former client libraries and has been replaced by 8126.

### Tracing from other containers
As with DogStatsD, traces can be submitted to the agent from other containers either
using the Docker host IP or with Docker links

#### Using Docker links
```
docker run  --name my_container           \
            --all_your_flags              \
            --link dd-agent:dd-agent    \
            my_image
```
will expose `DD_AGENT_PORT_8126_TCP_ADDR` and `DD_AGENT_PORT_8126_TCP_PORT` as environment variables. Your application tracer can be configured to submit to this address.

An example in Python:
```
import os
from ddtrace import tracer
tracer.configure(
    hostname=os.environ["DD_AGENT_PORT_8126_TCP_ADDR"],
    port=os.environ["DD_AGENT_PORT_8126_TCP_PORT"]
)
```

#### Using Docker host IP

Agent container port 8126 should be linked to the host directly, Having determined the address of the default route of this container, with `ip route` for example, you can configure your application tracer to report to it.

An example in python, assuming `172.17.0.1` is the default route:
```
from ddtrace import tracer; tracer.configure(hostname="172.17.0.1", port=8126)
```

## Build an image

To configure specific settings of the agent directly in the image, you may need to build a Docker image on top of ours.

1. Create a `Dockerfile` to set your specific configuration or to install dependencies.

    ```
    FROM datadog/docker-dd-agent
    # Example: MySQL
    ADD conf.d/mysql.yaml /etc/dd-agent/conf.d/mysql.yaml
    ```

2. Build it.

    `docker build -t dd-agent-image .`

3. Then run it like the `datadog/docker-dd-agent` image.

    ```
    docker run -d --name dd-agent \
      -v /var/run/docker.sock:/var/run/docker.sock:ro \
      -v /proc/:/host/proc/:ro \
      -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
      -e API_KEY={your_api_key_here} \
      dd-agent-image
    ```

4. It's done!

You can find [some examples](https://github.com/DataDog/docker-dd-agent/tree/master/examples) in our Github repository.


## Alpine-based image

Starting from Agent 5.7 we also provide an image based on [Alpine Linux](https://alpinelinux.org/). This image is smaller (about 60% the size of the Debian based one), and benefits from Alpine's security-oriented design.
It is compatible with all options described in this file (service discovery, enabling specific integrations, etc.) with the exception of Tracing and APM (the trace-agent does not ship with the Alpine images).

This image is available under tags with the following naming convention `usual_tag_name-alpine`. So for example to use the latest tag: `datadog/docker-dd-agent:latest-alpine` must be pulled. To use a specific version number, specify `11.2.583-alpine`.

The Alpine version can be used this way:

    ```
    docker run -d --name dd-agent \
      -v /var/run/docker.sock:/var/run/docker.sock:ro \
      -v /proc/:/host/proc/:ro \
      -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
      -e API_KEY={your_api_key_here} \
      datadog/docker-dd-agent:latest-alpine
    ```

**Note**: In this version, check configuration files must be stored in `/opt/datadog-agent/agent/conf.d/` instead of `/etc/dd-agent/conf.d/`.

**Warning**: This version is recent, and its behaviour may differ a little (namely, it is running a source-installed agent so commands need to be adapted). If you find a bug, don't hesitate to file an issue, feedback around it is appreciated.


## Versioning pattern

The docker image is following a versioning pattern that allows us to release changes to the Docker image of the Datadog Agent but with the same version of the Agent.

The Docker image version follows the following pattern:

`X.Y.Z` where X is the major version of the Docker Image, Y is the minor version, Z will represent the Agent version.

e.g. the first version of the Docker image that bundled the Datadog Agent 5.5.0 was:
```
10.0.550
```


## Information

To display information about the Agent's state with this command.

debian:

`docker exec dd-agent service datadog-agent info`

alpine:

`docker exec dd-agent /opt/datadog-agent/bin/agent info`

Warning: the `docker exec` command is available only with Docker 1.3 and above.


## Logs


### Copy logs from the container to the host

That's the simplest solution. It imports container's log to one's host directory.

`docker cp dd-agent:/var/log/datadog /tmp/log-datadog-agent`


### Supervisor logs

Basic information about the Agent execution are available through the `logs` command.

`docker logs dd-agent`

Exec a shell on the container and tail logs (collector.log, forwarder.log and jmxfetch.log) for debugging.  The supervisor.log is available there as well but you can get that from `docker logs dd-agent` from the host.

alpine:

```
$ docker exec -it dd-agent ash
/opt/datadog-agent # tail -f /opt/datadog-agent/logs/dogstatsd.log
2016-07-22 23:09:09 | INFO | dd.dogstatsd | dogstatsd(dogstatsd.py:210) | Flush #8: flushed 1 metric, 0 events, and 0 service check runs
```

debian:

```
$ docker exec -it dd-agent bash
# tail -f /var/log/datadog/dogstatsd.log
2016-07-22 23:09:09 | INFO | dd.dogstatsd | dogstatsd(dogstatsd.py:210) | Flush #8: flushed 1 metric, 0 events, and 0 service check runs
```


## Limitations

The Agent won't be able to collect disk metrics from volumes that are not mounted to the Agent container. If you want to monitor additional partitions, make sure to share them to the container in your docker run command (e.g. `-v /data:/data:ro`)

Docker isolates containers from the host. As a result, the Agent won't have access to all host metrics.

Known missing/incorrect metrics:

* Network
* Process list

Also, several integrations might be incomplete. See the "Contribute" section.


## Contribute

If you notice a limitation or a bug with this container, feel free to open a [Github issue](https://github.com/DataDog/docker-dd-agent/issues). If it concerns the Agent itself, please refer to its [documentation](https://docs.datadoghq.com/) or its [wiki](https://github.com/DataDog/dd-agent/wiki).
