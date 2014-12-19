# Datadog Agent Dockerfile

This repository is meant to build the base image for a Datadog Agent container. You will have to use the resulting image to configure and run the Agent.


## Quick Start

The default image is ready-to-go, you just need to set your hostname and API_KEY in the environment. Don't forget to set the `--privileged` flag and to mount some directories to get host metrics.

```
docker run -d --privileged --name dd-agent -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/mounts:/host/proc/mounts:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here} datadog/docker-dd-agent
```


## Usage

**Warning**: some procedures use `docker exec`, a command available only with Docker 1.3 and above.


### Configuration

#### Environment variables

A few parameters can be changed with environement variables.

* `TAGS` set host tags. Add `-e TAGS="mytag0,mytag1"` to use [mytag0, mytag1] as host tags.
* `LOG_LEVEL` set logging verbosity (CRITICAL, ERROR, WARNING, INFO, DEBUG). Add `-e LOG_LEVEL=DEBUG` to turn logs to debug mode.

#### Build an image

To configure integrations or custom checks, you will need to build a Docker image on top of our image.

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
docker run -d --privileged --name dd-agent -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/mounts:/host/proc/mounts:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here} dd-agent-image
```

4. It's done!

You can find [some examples](https://github.com/DataDog/docker-dd-agent/tree/master/examples) in our Github repository.


### Information

To display information about the Agent's state with this command.

`docker exec dd-agent service datadog-agent info`


### Logs

#### Copy logs from the container to the host

That's the simplest solution. It imports container's log to one's host directory.

`docker cp dd-agent:/var/log/datadog /tmp/log-datadog-agent`

#### Supervisor logs

Basic information about the Agent execution are available through the `logs` command.

`docker logs dd-agent`


## DogStatsD

To run DogStatsD without the full Agent, add the command `dogstatsd` at the end of the `docker run` command.

```
docker run -d --privileged --name dogstatsd -h `hostname` -v /var/run/docker.sock:/var/run/docker.sock -v /proc/mounts:/host/proc/mounts:ro -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro -e API_KEY={your_api_key_here} datadog/docker-dd-agent dogstatsd
```

Previous usage commands work, but there are some simpler ones when DogStatsD is running apart.


### Information

To display dogstatsd-only information.

`docker exec dogstatsd dogstatsd info`


### Logs

The previous methods will work, but this one is simpler when you run DogStatsD alone.

`docker logs dogstatsd`


## Limitations

**WARNING**: Even with the `--privileged` flag, the Agent won't have access to some metrics or events.

Known missing/incorrect metrics:

* Network
* Process list
* CPU


## Contribute

If you notice a limitation or a bug with this container, feel free to open a [Github issue](https://github.com/DataDog/docker-dd-agent/issues). If it concerns the Agent itself, please refer to its [documentation](http://docs.datadoghq.com/) or its [wiki](https://github.com/DataDog/dd-agent/wiki).
