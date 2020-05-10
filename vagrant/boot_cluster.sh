#!/bin/sh
set -ex

BASEDIR=$(dirname "$0")
cd $BASEDIR

. ./settings.rc

supervisorctl reload

ZK_REAL_PORT=$(( $ZK_REAL_PORT_BASE + 1 ))
# make sure the broker is up
while ! nc -q 1 localhost ${ZK_REAL_PORT} </dev/null; do echo "Waiting for Zookeeper"; sleep 1; done

# make sure toxiproxy is up
while ! nc -q 1 localhost ${TOXIPROXY_PORT} </dev/null; do echo "Waiting for Toxiproxy"; sleep 1; done
echo "It takes sometime for toxiproxy API to be ready"
sleep 60

# submit toxiproxy config
for N in $(seq 1 $NUM_INSTANCES); do
    # Zookeeper
    ZK_NAME="zookeeper-${N}"
    ZK_PROXY_PORT=$(( $ZK_PROXY_PORT_BASE + $N ))
    ZK_REAL_PORT=$(( $ZK_REAL_PORT_BASE + $N ))
    ${BIN}/toxiproxy-cli create $ZK_NAME -l 0.0.0.0:$ZK_PROXY_PORT -u localhost:$ZK_REAL_PORT

    # Kafka
    KAFKA_NAME="kafka-${N}"
    KAFKA_PROXY_PORT=$(( $KAFKA_PROXY_PORT_BASE + $N ))
    KAFKA_REAL_PORT=$(( $KAFKA_REAL_PORT_BASE + $N ))
    ${BIN}/toxiproxy-cli create $KAFKA_NAME -l 0.0.0.0:$KAFKA_PROXY_PORT -u $KAFKA_HOSTNAME:$KAFKA_REAL_PORT
done	 

# make sure the proxied Zookeeper is up
while ! nc -q 1 localhost ${ZK_PROXY_PORT} </dev/null; do echo "Waiting for Zookeeper via Toxiproxy"; sleep 1; done

# make sure the proxied Kafka is up
for N in $(seq 1 $NUM_INSTANCES); do
    KAFKA_PROXY_PORT=$(( $KAFKA_PROXY_PORT_BASE + $N ))
    while ! nc -q 1 ${KAFKA_HOSTNAME} ${KAFKA_PROXY_PORT} </dev/null; do echo "Waiting for Kafka ${N} via Toxiproxy"; sleep 1; done
done
echo "Boot completed.  Services are runing"

