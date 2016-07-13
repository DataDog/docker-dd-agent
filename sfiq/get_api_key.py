import logging
import os

from crypy.client import Client

logging.basicConfig(level=logging.INFO)

def get_dd_key():
    dcos_env = 'ops'
    if 'DCOS_ENV' in os.environ:
        dcos_env = os.environ['DCOS_ENV']
    cc = Client('dcos', crypter_env=dcos_env)
    dd_key = cc.read_credential('DD_API_KEY')
    return dd_key

if __name__ == '__main__':
    print get_dd_key()
