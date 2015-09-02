# How to run dd-agent in CoreOS

1. Deploy API key to etcd: `etcdctl set /datadog/apikey abcdefghijklmnopqrstuvwxzy`
1. Load the agent unit into fleet: `fleetctl load dd-agent.service`
1. Start the agent everywhere : `fleetctl start dd-agent.service`
