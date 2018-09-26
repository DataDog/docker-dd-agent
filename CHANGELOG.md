# Changes

## 12.7.5271 / 2018-09-26

- expose histogram_aggregates setting as environment variable

## 12.6.5223 / 2018-03-16

- [DEBIAN] use the new GPG signing key for the apt.datadoghq.com repository
- [DEBIAN] fix the status command
- [ALL IMAGES] add support for max_traces_per_second option to datadog.conf [#291](https://github.com/DataDog/docker-dd-agent/pull/291)
- [DEBIAN] update the Debian base image to stretch
- [JMX] ship openjdk 8u151

## 12.5.5202 / 2018-01-04

###

- [ALL IMAGES] move the supervisord socket to `/dev/shm/` to work around a bug in some
versions of the overlay filesystem (see #269 and #270)

## 12.3.5172 / 2017-09-19

### Changes

- [ALL IMAGES] un-expose supervisor port (see https://github.com/DataDog/docker-dd-agent/commit/980c892ce415e4b285466b4c2ac36afb87106d0c)
- [ALL IMAGES] update non-local traffic default configuration to false (see #241)
