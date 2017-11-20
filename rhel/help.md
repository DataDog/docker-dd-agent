% IMAGE_NAME(1)
% MAINTAINER
% DATE

# DESCRIPTION

The Datadog Agent provides real-time performance tracking and visualization of your containers, orchestrators,
operating system and application metrics.

# SUPPORT

Datadog's support team is available to assist you with any Datadog Agent related issues.
Support can be reached via [ticket](http://docs.datadoghq.com/help/), chat or other channels.

Please remember to [send your logs](https://help.datadoghq.com/hc/en-us/articles/204991415-Send-logs-and-configs-to-Datadog-via-flare-command)
as part of your case.

# USAGE

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


### Autodiscovery

The commands in the **Quick Start** section enable Autodiscovery in auto-conf mode, meaning the Agent will automatically run checks against any containers running images listed in the default check templates.

To learn more about Autodiscovery, read the [Autodiscovery guide](https://docs.datadoghq.com/guides/autodiscovery/) on the Datadog Docs site. To disable it, omit the `SD_BACKEND` environment variable when starting docker-dd-agent.


### Environment variables

Some configuration parameters can be changed with environment variables:

* `DD_HOSTNAME` set the hostname (write it in `datadog.conf`)
* `TAGS` set host tags. Add `-e TAGS=simple-tag-0,tag-key-1:tag-value-1` to use [simple-tag-0, tag-key-1:tag-value-1] as host tags.
* `EC2_TAGS` set EC2 host tags. Add `-e EC2_TAGS=yes` to use EC2 custom host tags. Requires an [IAM role](https://github.com/DataDog/dd-agent/wiki/Capturing-EC2-tags-at-startup) associated with the instance.
* `LOG_LEVEL` set logging verbosity (CRITICAL, ERROR, WARNING, INFO, DEBUG). Add `-e LOG_LEVEL=DEBUG` to turn logs to debug mode.
* `DD_LOGS_STDOUT` sends all logs to stdout and stderr, for them to be processed by Docker.
* `PROXY_HOST`, `PROXY_PORT`, `PROXY_USER` and `PROXY_PASSWORD` set the proxy configuration.
* `DD_URL` set the Datadog intake server to send Agent data to (used when [using an agent as a proxy](https://github.com/DataDog/dd-agent/wiki/Proxy-Configuration#using-the-agent-as-a-proxy) )
* `NON_LOCAL_TRAFFIC` tells the image to set the `non_local_traffic: true` option, which enables statsd reporting from any external ip. You may find this useful to report metrics from your other containers. See [network configuration](https://github.com/DataDog/dd-agent/wiki/Network-Traffic-and-Proxy-Configuration) for more details.
* ~~`DOGSTATSD_ONLY` tell the image to only start a standalone dogstatsd instance.~~ **[deprecated]: please use [the dogstatsd-only image](#standalone-dogstatsd)**
* `SD_BACKEND`, `SD_CONFIG_BACKEND`, `SD_BACKEND_HOST`, `SD_BACKEND_PORT`, `SD_TEMPLATE_DIR`, `SD_CONSUL_TOKEN`, `SD_BACKEND_USER` and `SD_BACKEND_PASSWORD` configure Autodiscovery (previously known as Service Discovery):

   - `SD_BACKEND`: set to `docker` (the only supported backend) to enable Autodiscovery.
   - `SD_CONFIG_BACKEND`: set to `etcd`, `consul`, or `zookeeper` to use one of these key-value stores as a template source.
   - `SD_BACKEND_HOST` and `SD_BACKEND_PORT`: configure the connection to the key-value template source.
   - `SD_TEMPLATE_DIR`: when using SD_CONFIG_BACKEND, set the path where the check configuration templates are located in the key-value store (default is `datadog/check_configs`)
   - `SD_CONSUL_TOKEN`: when using Consul as a template source and the Consul cluster requires authentication, set a token so the Datadog Agent can connect.
   - `SD_BACKEND_USER` and `SD_BACKEND_PASSWORD`: when using etcd as a template source and it requires authentication, set a user and password so the Datadog Agent can connect.

* `DD_APM_ENABLED` run the trace-agent along with the infrastructure agent, allowing the container to accept traces on 8126/tcp (**This option is NOT available on Alpine Images**)

**Note:** it is possible to use `DD_TAGS` instead of `TAGS`, `DD_LOG_LEVEL` instead of `LOG_LEVEL` and `DD_API_KEY` instead of `API_KEY`, these variables have the same impact.


### Enabling integrations

#### Environment variables

It is possible to enable some checks through the environment:

* `KUBERNETES` enables the kubernetes check if set (`KUBERNETES=yes` works). `KUBERNETES_COLLECT_EVENTS` enables event collection from the kubernetes API, given that `KUBERNETES` is also set. **Note:** only one agent should have `KUBERNETES_COLLECT_EVENTS` set per cluster.
* to collect the `kube_service` tags, the agent needs to query the apiserver's events and services endpoints. If you need to disable that, you can pass `KUBERNETES_COLLECT_SERVICE_TAGS=false`.
* the kubelet API endpoint is assumed to be the default route of the container, you can override the kubelet API endpoint by specifying `KUBERNETES_KUBELET_HOST` (eg. when using CNI networking, the kubelet API may not listen on the default route address)
* `MESOS_MASTER` and `MESOS_SLAVE` respectively enable the mesos master and mesos slave checks if set (`MESOS_MASTER=yes` works).
* `MARATHON_URL` if set will be used to enable the Marathon check that will query the URL passed in this variable for metrics. It can usually be set to `http://leader.mesos:8080`.

#### Autodiscovery

Another way to enable checks is through Autodiscovery. This is particularly useful in dynamic environments like Kubernetes, Amazon ECS, or Docker Swarm. Read more about Autodiscovery on the [Datadog Docs site](https://docs.datadoghq.com/guides/autodiscovery/).

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

# Source Code

Datadog's agent is open-source and avaiable on Github in the following respositories:

* [Datadog Agent](https://github.com/DataDog/dd-agent/)
* [Docker Container](https://github.com/DataDog/docker-dd-agent/)
* [Integrations](https://github.com/DataDog/integrations-core)
