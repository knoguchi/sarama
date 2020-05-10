#!/bin/sh
set -e

# This scripts install following apps to $INSTALL_ROOT
# - kafka and bundled zookeeper
# - toxiproxy

BASEDIR=$(dirname "$0")
. $BASEDIR/settings.rc

mkdir -p ${INSTALL_ROOT}/bin ${INSTALL_ROOT}/log

##### DOWNLOAD KAFKA #####
KAFKA=kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}

if [ ! -f /vagrant/vagrant/${KAFKA}.tgz ]; then
    wget --quiet https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KAFKA}.tgz -O /vagrant/vagrant/${KAFKA}.tgz
fi

tar xzf /vagrant/vagrant/${KAFKA}.tgz -C ${INSTALL_ROOT}
rm -f ${INSTALL_ROOT}/kafka
ln -s ${INSTALL_ROOT}/${KAFKA} ${INSTALL_ROOT}/kafka
	 
##### DOWNLOAD TOXIPROXY #####
TOXIPROXY=toxiproxy-${TOXIPROXY_VERSION}
if [ ! -f ${BIN}/toxiproxy ]; then
    wget -O ${BIN}/toxiproxy https://github.com/Shopify/toxiproxy/releases/download/v${TOXIPROXY_VERSION}/toxiproxy-server-linux-amd64
    chmod +x ${BIN}/toxiproxy

    wget -O ${BIN}/toxiproxy-cli https://github.com/Shopify/toxiproxy/releases/download/v${TOXIPROXY_VERSION}/toxiproxy-cli-linux-amd64
    chmod +x ${BIN}/toxiproxy-cli
fi


