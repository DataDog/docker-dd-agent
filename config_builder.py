#!/opt/datadog-agent/embedded/bin/python
'''
This script is used to generate the configuration of the datadog agent.
'''

from os import getenv, environ
import logging
from urllib2 import urlopen, URLError, HTTPError
from socket import getdefaulttimeout, setdefaulttimeout
from ConfigParser import ConfigParser


class ConfBuilder(object):
    '''
    This class manages the configuration files
    '''
    def __init__(self):
        # excludes from the generic variables parsing the ones that have a
        # certain logic warpped around them
        self.exclude_from_generic = [
            'DD_API_KEY', 'DD_API_KEY_FILE', 'DD_HOME',
            'DD_START_AGENT', 'DD_LOGS_STDOUT'
            ]
        dd_agent_root = '/etc/dd-agent'
        dd_home = getenv('DD_HOME')
        if dd_home is not None:
            dd_agent_root = '{}/agent'.format(dd_home)
        self.datadog_conf_file = '{}/datadog.conf'.format(dd_agent_root)
        # This will store the config parser object that is used in the different functions
        self.config = None

    def load_config(self, config_file):
        '''
        Loads a config file using ConfigParser
        '''
        self.config = ConfigParser()
        # import existing config from file
        with open(config_file, 'rb') as cfd:
            self.config.readfp(cfd)

    def save_config(self, config_file):
        '''
        Saves a ConfigParser object (self.config) to the given file
        '''
        if self.config is None:
            logging.error('config object needs to be created before saving anything')
            exit(1)
        with open(config_file, 'wb') as cfd:
            self.config.write(cfd)

    def build_datadog_conf(self):
        '''
        Builds the datadog.conf based on the environment variables
        '''
        self.load_config(self.datadog_conf_file)

        ##### Core config #####
        self.set_api_key()
        self.set_from_env_mapping('DD_HOSTNAME', 'hostname')
        self.set_from_env_mapping('EC2_TAGS', 'collect_ec2_tags')
        # The TAGS env variable superseeds DD_TAGS
        self.set_from_env_mapping('DD_TAGS', 'tags')
        self.set_from_env_mapping('TAGS', 'tags')
        self.set_from_env_mapping('DD_COLLECT_LABELS_AS_TAGS', 'docker_labels_as_tags')
        # The LOG_LEVEL env variable superseeds DD_LOG_LEVEL
        self.set_from_env_mapping('DD_LOG_LEVEL', 'log_level')
        self.set_from_env_mapping('LOG_LEVEL', 'log_level')
        self.set_from_env_mapping('NON_LOCAL_TRAFFIC', 'non_local_traffic')
        self.set_from_env_mapping('DD_URL', 'dd_url')
        self.set_from_env_mapping('STATSD_METRIC_NAMESPACE', 'statsd_metric_namespace')
        self.set_from_env_mapping('USE_DOGSTATSD', 'use_dogstatsd')
        # Histogram Aggregates and Histogram Percentile configuration
        self.set_from_env_mapping('DD_HISTOGRAM_AGGREGATES', 'histogram_aggregates')
        self.set_from_env_mapping('DD_HISTOGRAM_PERCENTILES', 'histogram_percentiles')
        ##### Proxy config #####
        self.set_from_env_mapping('PROXY_HOST', 'proxy_host')
        self.set_from_env_mapping('PROXY_PORT', 'proxy_port')
        self.set_from_env_mapping('PROXY_USER', 'proxy_user')
        self.set_from_env_mapping('PROXY_PASSWORD', 'proxy_password')
        ##### Service discovery #####
        self.set_from_env_mapping('SD_BACKEND', 'service_discovery_backend')
        self.set_sd_backend_host()
        self.set_from_env_mapping('SD_BACKEND_PORT', 'sd_backend_port')
        self.set_from_env_mapping('SD_TEMPLATE_DIR', 'sd_template_dir')
        self.set_from_env_mapping('SD_CONSUL_TOKEN', 'consul_token')
        self.set_from_env_mapping('SD_BACKEND_USER', 'sd_backend_username')
        self.set_from_env_mapping('SD_BACKEND_PASSWORD', 'sd_backend_password')
        # Magic trick to automatically add properties not yet define in the doc
        self.set_generics('DD_CONF_')
        ##### Trace Config #####
        self.set_from_env_mapping('MAX_TRACES_PER_SECOND', 'max_traces_per_second', 'trace.sampler')

        self.save_config(self.datadog_conf_file)

    def set_api_key(self):
        '''
        Used for building datadog.conf
        Gets the API key from the environment or the key file
        and sets it in the configuration
        '''
        api_key = getenv('DD_API_KEY', getenv('API_KEY', ''))
        keyfile = getenv('DD_API_KEY_FILE')
        if keyfile is not None:
            try:
                with open(keyfile, 'r') as kfile:
                    api_key = kfile.read()
            except IOError:
                logging.warning('Unable to read the content of they key file specified in DD_API_KEY_FILE')
        if len(api_key) <= 0:
            logging.error('You must set API_KEY environment variable or include a DD_API_KEY_FILE to run the Datadog Agent container')
            exit(1)
        self.set_property('api_key', api_key)

    def set_from_env_mapping(self, env_var_name, property_name, section='Main', action=None):
        '''
        Sets a property using the corresponding environment variable if it exists
        It also returns the value in case you want to play with it
        If action is specified to 'store_true', whatever the content of the
        env variable is (if exists), the value of the property will be true
        '''
        _val = getenv(env_var_name)
        if _val is not None:
            if action == 'store_true':
                _val = 'true'
            self.set_property(property_name, _val, section)
            return _val
        return None

    def set_sd_backend_host(self):
        '''
        Used for building datadog.conf
        Sets sd_config_backend and sd_backend_host depending on the environment
        '''
        _config_backend = getenv('SD_CONFIG_BACKEND')
        if _config_backend is not None:
            self.set_property('sd_config_backend', _config_backend)
            _backend_host = getenv('SD_BACKEND_HOST')
            if _backend_host is not None:
                self.set_property('sd_backend_host', _backend_host)
            else:
                _timeout = getdefaulttimeout()
                try:
                    setdefaulttimeout(1)
                    _ec2_ip = urlopen('http://169.254.169.254/latest/meta-data/local-ipv4')
                    self.set_property('sd_backend_host', _ec2_ip.read())
                except (URLError, HTTPError):
                    pass  # silent fail on purpose
                setdefaulttimeout(_timeout)

    def set_generics(self, prefix='DD_CONF_'):
        '''
        Looks for environment variables starting by the given prefix and consider that the
        rest of the variable name is the name of the property to set
        '''
        for dd_var in environ:
            if dd_var.startswith(prefix) and dd_var.upper() not in self.exclude_from_generic:
                if len(dd_var) > 0:
                    self.set_property(dd_var[len(prefix):].lower(), environ[dd_var])

    def set_property(self, property_name, property_value, section='Main'):
        '''
        Sets the given property to the given value in the configuration
        '''
        if not self.config.has_section(section):
            self.config.add_section(section)
        if self.config is None:
            logging.error('config object needs to be created before setting properties')
            exit(1)
        self.config.set(section, property_name, property_value)

if __name__ == '__main__':
    cfg = ConfBuilder()
    cfg.build_datadog_conf()
