import logging

from crypy.client import Client

logging.basicConfig(level=logging.INFO)

def get_key():
    cc = Client('dcos', crypter_env='ops')
    return cc.read_credential('DD_API_KEY')

if __name__ == '__main__':
    print get_key()
