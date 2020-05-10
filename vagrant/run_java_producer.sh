#!/bin/sh

set -ex
BASEDIR=$(dirname "$0")
. $BASEDIR/settings.rc

JAR=simplest-uncommitted-msg-0.1-jar-with-dependencies.jar
if [ ! -f ${BASEDIR}/${JAR} ]; then
    wget https://github.com/FrancoisPoinsot/simplest-uncommitted-msg/releases/download/0.1/${JAR}
fi
java -jar simplest-uncommitted-msg-0.1-jar-with-dependencies.jar -b ${KAFKA_HOSTNAME}:9092 -c 4
