#!/bin/sh

set -ex
BASEDIR=$(dirname "$0")
. $BASEDIR/settings.rc

cd ${INSTALL_ROOT}/kafka
while !  ./bin/kafka-topics.sh --bootstrap-server ${KAFKA_HOSTNAME}:9092 --create --partitions 1 --replication-factor 3 --topic test.1; do
    echo "Kafka cluster might not be ready"
    sleep 1
done
./bin/kafka-topics.sh --bootstrap-server ${KAFKA_HOSTNAME}:9092 --create --partitions 4 --replication-factor 3 --topic test.4
./bin/kafka-topics.sh --bootstrap-server ${KAFKA_HOSTNAME}:9092 --create --partitions 64 --replication-factor 3 --topic test.64
./bin/kafka-topics.sh --bootstrap-server ${KAFKA_HOSTNAME}:9092 --create --partitions 1 --replication-factor 3 --topic uncommitted-topic-test-4
