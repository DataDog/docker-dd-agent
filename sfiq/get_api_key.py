import os

from crypy.client import Client

def get_dd_key():
    dcos_env = 'ops'
    if 'DCOS_ENV' in os.environ:
        dcos_env = os.environ['DCOS_ENV']
    cc = Client('dcos', crypter_env=dcos_env)
    dd_key = cc.read_credential('datadog_api_key')
    return dd_key

if __name__ == '__main__':
    print get_dd_key()
