# Datadog Agent Dockerfile

This repository is meant to build the base image for a Datadog Agent container. You will have to use the resulting image to configure and run the Agent.


## Quick Start

The default image is ready-to-go. You just need to set your hostname and API_KEY in the environment.

```
docker run -d --name dd-agent -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/:/host/proc/:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here} datadog/docker-dd-agent
```

If you are running on Amazon Linux, use the following instead:

```
docker run -d --name dd-agent -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/:/host/proc/:ro -v /cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here}
datadog/docker-dd-agent
```

## Versioning

As per Agent 5.5.0. The docker image is following a new versioning pattern to allow us to release changes to the Docker image of the Datadog Agent but with the same version of the Agent.

The Docker image version will have the following pattern:

`X.Y.Z` where X is the major version of the Docker Image, Y is the minor version, Z will represent the Agent version.

e.g. the first version of the Docker image that will bundle the Datadog Agent 5.5.0 will be:
```
10.0.550
```

## Configuration

### Environment variables

A few parameters can be changed with environment variables.

* `TAGS` set host tags. Add `-e TAGS="simple-tag-0,tag-key-1:tag-value-1"` to use [simple-tag-0, tag-key-1:tag-value-1] as host tags.
* `LOG_LEVEL` set logging verbosity (CRITICAL, ERROR, WARNING, INFO, DEBUG). Add `-e LOG_LEVEL=DEBUG` to turn logs to debug mode.
* `PROXY_HOST`, `PROXY_PORT`, `PROXY_USER` and `PROXY_PASSWORD` set the proxy configuration.
* `DD_URL` set the Datadog intake server to send Agent data to (used when [using an agent as a proxy](https://github.com/DataDog/dd-agent/wiki/Proxy-Configuration#using-the-agent-as-a-proxy) )
* `DOGSTATSD_ONLY` tell the image to only start a standalone dogstatsd instance.

### Enabling integrations

To enable integrations you can write your YAML configuration files in the `/conf.d` folder, they will automatically be copied to `/etc/dd-agent/conf.d/` when the container starts.  You can also do the same for the `/checks.d` folder.   Any Python files in the `/checks.d` folder will automatically be copied to the `/etc/dd-agent/conf.d/` when the container starts.

1. Create a configuration folder on the host and write your YAML files in it.  The examples below can be used for the `/checks.d` folder as well.

    ```
    mkdir /opt/dd-agent-conf.d
    touch /opt/dd-agent-conf.d/nginx.yaml
    ```

2. When creating the container, mount this new folder to `/conf.d`.
    ```
    docker run -d --name dd-agent -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/:/host/proc/:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -v /opt/dd-agent-conf.d:/conf.d:ro -e API_KEY={your_api_key_here} datadog/docker-dd-agent
    ```

    _The important part here is `-v /opt/dd-agent-conf.d:/conf.d:ro`_

Now when the container starts, all files in `/opt/dd-agent-conf.d` with a `.yaml` extension will be copied to `/etc/dd-agent/conf.d/`. Please note that to add new files you will need to restart the container.

### Build an image

To configure specific settings of the agent straight in the image, you may need to build a Docker image on top of this image.

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
    docker run -d --name dd-agent -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/:/host/proc/:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here} dd-agent-image
    ```

4. It's done!

You can find [some examples](https://github.com/DataDog/docker-dd-agent/tree/master/examples) in our Github repository.


## Information

To display information about the Agent's state with this command.

`docker exec dd-agent service datadog-agent info`

Warning: the `docker exec` command is available only with Docker 1.3 and above.

## Logs

### Copy logs from the container to the host

That's the simplest solution. It imports container's log to one's host directory.

`docker cp dd-agent:/var/log/datadog /tmp/log-datadog-agent`

### Supervisor logs

Basic information about the Agent execution are available through the `logs` command.

`docker logs dd-agent`


## DogStatsD

### Standalone DogStatsD

To run DogStatsD without the full Agent, add the `DOGSTATSD_ONLY` environment variable to the `docker run` command.

```
docker run -d --name dogstatsd -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/mounts:/host/proc/mounts:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here} -e DOGSTATSD_ONLY=true datadog/docker-dd-agent
```

This option allows you to run dogstatsd alone, without supervisor. One consequence of this is that the following command returns logs from dogstatsd directly instead of supervisor:

`docker logs dogstatsd`

### DogStatsD from the host

DogStatsD can be available on port 8125 from anywhere by adding the option `-p 8125:8125/udp` to the `docker run` command.

To make it available from your host only, use `-p 127.0.0.1:8125:8125/udp` instead.

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

Since the Agent container port 8125 should be linked to the host directly, you can connect to DogStatsD though the host. By default, the IP of the host in a Docker container is `172.17.42.1`. So you can configure your DogStatsD client to connect to `172.17.42.1:8125`.


## Limitations

The Agent won't be able to collect disk metrics from volumes that are not mounted to the Agent container. If you want to monitor additional partitions, make sure to share them to the container in your docker run command (e.g. `-v /data:/data:ro`)

Docker isolates containers from the host. As a result, the Agent won't have access to all host metrics.

Known missing/incorrect metrics:

* Network
* Process list

Also, several integrations might be incomplete. See the "Contribute" section.

## Contribute

If you notice a limitation or a bug with this container, feel free to open a [Github issue](https://github.com/DataDog/docker-dd-agent/issues). If it concerns the Agent itself, please refer to its [documentation](http://docs.datadoghq.com/) or its [wiki](https://github.com/DataDog/dd-agent/wiki).
