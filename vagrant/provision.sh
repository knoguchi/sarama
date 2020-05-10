#!/bin/sh

set -ex

FILES="install_cluster.sh setup_services.sh create_topics.sh run_java_producer.sh boot_cluster.sh halt_cluster.sh run_toxiproxy.sh"
DEBS="default-jre supervisor"

BASEDIR=/vagrant/vagrant
. $BASEDIR/settings.rc
cd $BASEDIR

apt-get update
yes | apt-get install $DEBS


mkdir -p $BIN
cp settings.rc $BIN
cp $FILES $BIN

sh ${BIN}/install_cluster.sh
sh ${BIN}/setup_services.sh
sh ${BIN}/create_topics.sh
sh ${BIN}/run_java_producer.sh
