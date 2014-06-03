# Datadog Agent Dockerfile

This repository is meant to build the base image for a Datadog Agent container. You will have to use the resulting image to configure and run the Agent.


## Quick Start

Create a `Dockerfile` to set your API key.

```
FROM datadog/docker-dd-agent

# Set your API key
RUN sed -i -e"s/^.*api_key:.*$/api_key: YOUR_API_KEY/" /etc/dd-agent/datadog.conf
```

Build it.

`docker build .`

Then run it with the `--privileged` flag.

`docker run -d -name dd-agent --privileged dd-agent_image_id`

Now, the Agent is reporting host metrics to Datadog.


## Integration configuration

The default setup only report system metrics. You can change parameters in `datadog.conf` file the same way as the API key. You can also add files to `/etc/dd-agent/conf.d` and install packages/modules to enable specific integrations.

Example with `Redis`, add to the `Dockerfile`:

```
RUN apt-get install python-redis -y
RUN mv /etc/dd-agent/conf.d/redis.yaml.example /etc/dd-agent/conf.d/redis.yaml
```

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

Create a volumes for the log directory when running the image.

`docker run -d -name dd-agent -v /var/log/datadog --privileged dd-agent_image_id`

Logs are now stored in a volume that you can access from other containers with the `--volumes-from` parameter. For examples, if you want to look into it:

`docker run --volumes-from dd-agent -name dd-agent-log-reader ubuntu /bin/bash`

It will open a shell, then go to `/var/log/datadog` to see Agent logs.


### Host directory as a volume

You can also use a host directory, let's say `/var/docker-volumes/dd-agent/log`, as a log directory.
When you run the dd-agent container:

`docker run -d -name dd-agent -v /var/docker-volumes/dd-agent/log:/var/log/datadog --privileged dd-agent_image_id`

Now you should see Agent logs into `/var/docker-volumes/dd-agent/log` on your host.


### Logging verbosity

You can set logging to DEBUG verbosity by adding to your `Dockerfile`:

```
RUN sed -i -e"s/^.*log_level:.*$/log_level: DEBUG/" /etc/dd-agent/datadog.conf
```

