# Swarm Connectivity Checker

This script will check your Docker Swarm configuration to ensure services can communicate between each other and across nodes. It is based on methods suggested in [this Gist](https://gist.github.com/alexellis/8e15f2ea1af7281268ec7274686985ba).

It assumes you have Docker Swarm installed and configured, and are running as a user that has access to Docker.

## Usage

Download and run `test-swarm.sh` on your Docker Swarm manager node.

## Example output
```
~# ./test-swarm.sh

Swarm Connectivity Checker v0.1

This script will check your Docker Swarm configuration to ensure services can communicate between each other and across nodes.
It assumes you have Docker Swarm installed and configured, and are running as a user that has access to Docker.

Press ENTER to begin the checks, or CTRL-C to abort.

Initial Setup:
- Creating network...    Network created successfully.

Testing overlay networking:
- Creating nginx service...    Service created successfully.
- Testing round robin overlay networking...
   HOST: swarm03 EST: 0.001268s TTFB: 0.001599s TOT: 0.001690s
   HOST: swarm02 EST: 0.000888s TTFB: 0.001444s TOT: 0.001633s
   HOST: swarm01 EST: 0.000721s TTFB: 0.000904s TOT: 0.001051s

- Cleaning up nginx service...   Service removed.

Testing inter-service connectivity:
- Creating redis service...   Service created successfully.
- Incrementing value in Redis datastore...   Value incremented as expected, check successful.

- Cleaning up redis service...   Service removed.

Cleanup:
- Removing network...   Network removed.

Complete!
```

