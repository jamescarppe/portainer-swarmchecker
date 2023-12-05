#!/bin/bash
NODECOUNT=$(docker info --format '{{json .Swarm.Nodes}}')
echo Creating network...
docker network create --driver overlay --attachable=true portainer-swarmtest
echo Creating service...
docker service create --network=portainer-swarmtest --name portainer-swarmtest-nginx --publish 8398 --replicas $NODECOUNT --mount type=bind,source=/etc/hostname,destination=/usr/share/nginx/html/index.html nginx:latest
sleep 2

echo Testing overlay networking...
x=1
while [ $x -le $NODECOUNT ]
do
  docker run --rm --name portainer-swarmtest-curl --net=portainer-swarmtest alpine:latest sh -c "apk add --no-cache curl > /dev/null && curl -s -w 'EST: %{time_connect}s TTFB: %{time_starttransfer}s TOT: %{time_total}s\n' portainer-swarmtest-nginx"
  x=$(( $x + 1 ))
done

echo Testing inter-service connectivity...

docker service create --network=portainer-swarmtest --name portainer-swarmtest-redis --publish 6379 --replicas=1 --constraint='node.role != manager' redis:latest

REDISRUNA=$(docker run --rm --name portainer-rediscli-a --net=portainer-swarmtest redis:latest redis-cli -h portainer-swarmtest-redis INCR portainer-swarmtest)
REDISRUNB=$(docker run --rm --name portainer-rediscli-b --net=portainer-swarmtest redis:latest redis-cli -h portainer-swarmtest-redis INCR portainer-swarmtest)

if [[ $REDISRUNB == 2 ]]; then
  echo "Increment successful: $REDISRUNA $REDISRUNB"
else
  echo "Increment FAILED: $REDISRUNA $REDISRUNB"
fi

echo Cleaning up...
docker service rm portainer-swarmtest-redis
docker service rm portainer-swarmtest-nginx
docker network rm portainer-swarmtest

echo Complete!
