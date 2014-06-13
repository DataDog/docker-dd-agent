# Datadog Agent Dockerfile

This repository is meant to build the base image for a Datadog Agent container. You will have to use the resulting image to configure and run the Agent.

Warning: Inside a container, the Datadog Agent is restricted. Some metrics won't be reported, some integration won't work. More information in our wiki: [Datadog Agent Docker container](https://github.com/DataDog/dd-agent/wiki/Docker-Containers).

## Quick Start

The default image is ready-to-go, you just need to set your hostname and API_KEY in the environment. Don't forget to set the `--privileged` flag to get host metrics.

```
docker run -d --privileged --name dd-agent -h `hostname` -e API_KEY=apikey_3 datadog/docker-dd-agent
```

## Configuration

To configure the Agent, you will need to build a Docker image on top of our image.

Create a `Dockerfile` to set your specific configuration or to install dependencies.

```
FROM datadog/docker-dd-agent

# Example: MySQL
RUN apt-get install python-mysqldb -qq --no-install-recommends
ADD mysql.yaml /etc/dd-agent/conf.d/mysql.yaml
```

Build it.

`docker build -t dd-agent-image .`

Then run it like the `datadog/docker-dd-agent` image.

`
docker run -d --privileged --name dd-agent -h `hostname` -e API_KEY=apikey_3 dd-agent-image
`

## DogStatsD

If you want to run DogStatsD alone, give a look at [docker-dogstatsd](https://github.com/DataDog/docker-dogstatsd).

This container also runs DogStatsD, so the documentation from [docker-dogstatsd](https://github.com/DataDog/docker-dogstatsd/blob/master/README.md) also apply to it.


## Logs

### Supervisor logs

Basic information about the Agent execution are available through the `logs` command.

`docker logs dd-agent`

If you want to get access to the real Agent logs, you will need to use volumes.
A full documentation of volumes is available on [Docker documentation](http://docs.docker.io/use/working_with_volumes/). Here are two examples.

### Container volume

Create a volumes for the log directory when running the image by adding `-v /var/log/datadog` to the `run` command.

Logs are now stored in a volume that you can access from other containers with the `--volumes-from` parameter. For examples, if you want to look into it:

`docker run --volumes-from dd-agent -name dd-agent-log-reader ubuntu /bin/bash`

It will open a shell, then go to `/var/log/datadog` to see Agent logs.


### Host directory as a volume

You can also use a host directory, let's say `/var/docker-volumes/dd-agent/log`, as a log directory. For that, add the option `-v /var/docker-volumes/dd-agent/log:/var/log/datadog`

Now you should see Agent logs into `/var/docker-volumes/dd-agent/log` on your host.


### Logging verbosity

You can set logging to DEBUG verbosity by adding to your `Dockerfile`:

```
RUN sed -i -e"s/^.*log_level:.*$/log_level: DEBUG/" /etc/dd-agent/datadog.conf
```

