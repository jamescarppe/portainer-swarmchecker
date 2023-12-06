#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
echo
echo Swarm Connectivity Checker v0.1
echo
echo This script will check your Docker Swarm configuration to ensure services can communicate between each other and across nodes.
echo It assumes you have Docker Swarm installed and configured, and are running as a user that has access to Docker.
echo
read -p "Press ENTER to begin the checks, or CTRL-C to abort."
echo
echo Initial Setup:

NODECOUNT=$(docker info --format '{{json .Swarm.Nodes}}')

echo -n "- Creating network... "
docker network create --driver overlay --attachable=true portainer-swarmtest > /dev/null
if [ $? -eq 0 ]; then
  echo -e "   ${GREEN}Network created successfully.${NC}"
else
  echo -e "   ${RED}Network creation failed, aborting.${NC}"
  exit 1
fi

echo
echo Testing overlay networking:

echo -n "- Creating nginx service... "
docker service create --network=portainer-swarmtest --name portainer-swarmtest-nginx --publish 8398 --replicas $NODECOUNT --mount type=bind,source=/etc/hostname,destination=/usr/share/nginx/html/index.html nginx:latest > /dev/null
if [ $? -eq 0 ]; then
  echo -e "   ${GREEN}Service created successfully.${NC}"
else
  echo -e "   ${RED}Service creation failed, aborting.${NC}"
  exit 1
fi

echo "- Testing round robin overlay networking... "
x=1
while [ $x -le $NODECOUNT ]
do
  NGINXRUN=$(docker run --rm --name portainer-swarmtest-curl --net=portainer-swarmtest alpine:latest sh -c "apk add --no-cache curl > /dev/null && curl -s -w 'EST: %{time_connect}s TTFB: %{time_starttransfer}s TOT: %{time_total}s\n\n' portainer-swarmtest-nginx")
  echo "   HOST: ${NGINXRUN//$'\n'/ }"
  x=$(( $x + 1 ))
done
sleep 2

echo
echo -n - Cleaning up nginx service...
docker service rm portainer-swarmtest-nginx > /dev/null
if [ $? -eq 0 ]; then
  echo -e "   ${GREEN}Service removed.${NC}"
else
  echo -e "   ${RED}Service removal FAILED, manual cleanup may be required.${NC}"
fi
sleep 2

echo
echo Testing inter-service connectivity:
echo -n - Creating redis service...
docker service create --network=portainer-swarmtest --name portainer-swarmtest-redis --publish 6379 --replicas=1 --constraint='node.role != manager' redis:latest > /dev/null
if [ $? -eq 0 ]; then
  echo -e "   ${GREEN}Service created successfully.${NC}"
else
  echo -e "   ${RED}Service creation failed, aborting.${NC}"
  exit 1
fi

echo -n - Incrementing value in Redis datastore...
REDISRUNA=$(docker run --rm --name portainer-swarmtest-rediscli-a --net=portainer-swarmtest redis:latest redis-cli -h portainer-swarmtest-redis INCR portainer-swarmtest)
REDISRUNB=$(docker run --rm --name portainer-swarmtest-rediscli-b --net=portainer-swarmtest redis:latest redis-cli -h portainer-swarmtest-redis INCR portainer-swarmtest)

if [[ $REDISRUNB == 2 ]]; then
  echo -e "   ${GREEN}Value incremented as expected, check successful.${NC}"
else
  echo -e "   ${RED}Value increment FAILED:${NC} $REDISRUNA $REDISRUNB"
fi
sleep 2

echo
echo -n - Cleaning up redis service...
docker service rm portainer-swarmtest-redis > /dev/null
if [ $? -eq 0 ]; then
  echo -e "   ${GREEN}Service removed.${NC}"
else
  echo -e "   ${RED}Service removal FAILED, manual cleanup may be required.${NC}"
fi
sleep 1

echo
echo Cleanup:
echo -n - Removing network...
docker network rm portainer-swarmtest > /dev/null
if [ $? -eq 0 ]; then
  echo -e "   ${GREEN}Network removed.${NC}"
else
  echo -e "   ${RED}Network removal FAILED, manual cleanup may be required.${NC}"
fi

echo
echo Complete!