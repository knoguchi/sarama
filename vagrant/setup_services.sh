#!/bin/sh
set -e

BASEDIR=$(dirname "$0")
cd $BASEDIR

. ./settings.rc

supervisorctl stop all

cat > toxiproxy.conf <<EOF
[program:toxiproxy]
command=${BIN}/toxiproxy -port ${TOXIPROXY_PORT} -host 0.0.0.0
stdout_logfile = ${LOG}/toxiproxy-stdout.log
stderr_logfile = ${LOG}/toxiproxy-stderr.log
EOF
cp toxiproxy.conf /etc/supervisor/conf.d/toxiproxy.conf

# zookeeper config and supervisor config
rm -f zookeeper.conf
for N in $(seq 1 $NUM_INSTANCES); do
    # zookeeper config
    ZK_REAL_PORT=$(( $ZK_REAL_PORT_BASE + $N ))
    ZK_DIR=$INSTALL_ROOT/zookeeper-$N
    mkdir -p $ZK_DIR
    echo $N > $ZK_DIR/myid
    sed -e "s|^[#|\s]*dataDir=.*|dataDir=${ZK_DIR}|" \
        -e "s|^[#|\s]*clientPort=.*|clientPort=${ZK_REAL_PORT}|" \
        -e "s|^[#|\s]*maxClientCnxns=.*|maxClientCnxns=0|" \
        -e "s|^[#|\s]*tickTime=.*|tickTime=2000|" \
        -e "s|^[#|\s]*initLimit=.*|initLimit=10|" \
        -e "s|^[#|\s]*syncLimit=.*|syncLimit=10|" \
        < $INSTALL_ROOT/kafka/config/zookeeper.properties > $ZK_DIR/zookeeper.properties
    cat >> $ZK_DIR/zookeeper.properties <<EOF
tickTime=2000
initLimit=10
syncLimit=10
EOF

    for M in $(seq 1 $NUM_INSTANCES); do
	ZK_REAL_PORT1=$(( $ZK_REAL_PORT1_BASE + $M ))
	ZK_REAL_PORT2=$(( $ZK_REAL_PORT2_BASE + $M ))
	echo "server.${M}=localhost:${ZK_REAL_PORT1}:${ZK_REAL_PORT2}" >> $ZK_DIR/zookeeper.properties
    done

    # supervisor config
    cat >> zookeeper.conf <<EOF
[program:zookeeper-${N}]
command=${INSTALL_ROOT}/kafka/bin/zookeeper-server-start.sh ${INSTALL_ROOT}/zookeeper-${N}/zookeeper.properties
stdout_logfile = ${LOG}/zookeeper-${N}-stdout.log
stderr_logfile = ${LOG}/zookeeper-${N}-stderr.log
environment = KAFKA_HEAP_OPTS="-Xmx192m -Dzookeeper.admin.enableServer=false"
EOF
done
cp zookeeper.conf /etc/supervisor/conf.d/zookeeper.conf

# kafka server.properties and supervisor config
rm -f kafka.conf
for N in $(seq 1 $NUM_INSTANCES); do
    # set up kafka service
    KAFKA_REAL_PORT=$(( $KAFKA_REAL_PORT_BASE + $N))
    KAFKA_PROXY_PORT=$(( $KAFKA_PROXY_PORT_BASE + $N ))
    KAFKA_DIR=$INSTALL_ROOT/kafka-${N}
    mkdir -p $KAFKA_DIR/data
    sed -e "s|^[#|\s]*broker.id=.*|broker.id=${N}|" \
        -e "s|^[#|\s]*broker.rack=.*|broker.rack=${N}|" \
        -e "s|^[#|\s]*log.dirs=.*|log.dirs=${KAFKA_DIR}\/data|" \
        -e "s|^[#|\s]*listeners=.*|listeners=PLAINTEXT://${KAFKA_HOSTNAME}:${KAFKA_REAL_PORT}|" \
        -e "s|^[#|\s]*advertised.listeners=.*|advertised.listeners=PLAINTEXT://${KAFKA_HOSTNAME}:${KAFKA_PROXY_PORT}|" \
        -e "s|^[#|\s]*default.replication.factor=.*|default.replication.factor=2|" \
        -e "s|^[#|\s]*log.retention.bytes=.*|log.retention.bytes=268435456|" \
        -e "s|^[#|\s]*log.segment.bytes=.*|log.segment.bytes=268435456|" \
        -e "s|^[#|\s]*zookeeper.session.timeout.ms=.*|zookeeper.session.timeout.ms=3000|" \
        -e "s|^[#|\s]*zookeeper.connection.timeout.ms=.*|zookeeper.connection.timeout.ms=3000|" \
        -e "s|^[#|\s]*reserved.broker.max.id=10000=.*|reserved.broker.max.id=10000|" \
        -e "s|^[#|\s]*replica.selector.class=.*|replica.selector.class=org.apache.kafka.common.replica.RackAwareReplicaSelector|" \
        < $INSTALL_ROOT/kafka/config/server.properties > $KAFKA_DIR/server.properties

    cat >> kafka.conf <<EOF
[program:kafka-${N}]
command=${INSTALL_ROOT}/kafka/bin/kafka-server-start.sh ${INSTALL_ROOT}/kafka-${N}/server.properties
stdout_logfile = ${LOG}/kafka-${N}-stdout.log
stderr_logfile = ${LOG}/kafka-${N}-stderr.log
environment = KAFKA_HEAP_OPTS="-Xmx320m"

EOF

done

cp kafka.conf /etc/supervisor/conf.d/kafka.conf

./boot_cluster.sh
