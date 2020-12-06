#!/bin/bash

set -e
echo "========================================================================================="
echo "* Remember to set the correct values in env/airflow_env.env file                        *"
echo "* unless defaults are kept                                                              *"
echo "========================================================================================="

function error() {
    echo "Error: $1"
    exit -1
}

[ -z $1 ] && export SCALA_VERSION="2.11" || export SCALA_VERSION=$1
[ -z $2 ] && export LIB_VERSION="0.1" || export LIB_VERSION=$2
[ -z $3 ] && export JAR_NAME="streaming-lib-assembly" || export JAR_NAME=$3
[ -z $4 ] && export JAR_DEST="target/scala-$SCALA_VERSION/$JAR_NAME-$LIB_VERSION.jar" || export JAR_DEST=$4
[ -z $5 ] && export CP_VERSION="6.0.0-post" || export CP_VERSION=$5

echo "********************************************************************************************"
echo "*                                                                                          "
echo "* Using SCALA_VERSION=$SCALA_VERSION                                                       "
echo "* Using LIB_VERSION=$LIB_VERSION                                                           "
echo "* Using JAR_DEST=$JAR_DEST                                                                 "
echo "* Using CP_VERSION=$CP_VERSION                                                             "
echo "*                                                                                          "
echo "* To override, execute script with args in this order:                                     "
echo "* bash run.sh <scala_version> <lib_version> <jar_name> <jar_dest> <cp_version>             "
echo "*                                                                                          "
echo "********************************************************************************************"

echo "Checking python existence..."
[[ $(which python) =~ $"python" ]] || error "Expected python to exist in host"
echo "Python is $(which python)"

# clone spark streaming lib
[ -d structured-streaming-lib ] || git clone https://github.com/jsoft88/structured-streaming-lib.git

cd structured-streaming-lib

[ -f $JAR_DEST ] || sbt assembly

# make it available to Dockerfile
cp $JAR_DEST ../spark

# get kafka confluent platform
cd ..

[ -d cp-all-in-one ] || git clone https://github.com/confluentinc/cp-all-in-one.git

cd cp-all-in-one

git checkout $CP_VERSION

cd cp-all-in-one

docker-compose up -d

# add topic for output for streaming library
docker exec -it broker sh -c "kafka-topics --create --replication-factor 1 --partitions 1 --topic top_pages --bootstrap-server localhost:9092"
docker exec -it broker sh -c "kafka-topics --create --replication-factor 1 --partitions 1 --topic pageviews --bootstrap-server localhost:9092"
docker exec -it broker sh -c "kafka-topics --create --replication-factor 1 --partitions 1 --topic users --bootstrap-server localhost:9092"

sleep 5

echo "You can now visit http://localhost:9021 to see the kafka platform, select cluster 1 and later topics section. You should find pageviews, users and top_pages topics"
# get airflow puckel image
cd ../../

docker pull puckel/docker-airflow

# wait for a shared file named spark_command_ready appears under /tmp
docker run -d -p 8080:8080 \
--name airflow -v $(pwd)/env/airflow_env.json:/airflow_env.json \
-v $(pwd)/airflow/:/usr/local/airflow \
-e AIRFLOW__CORE__FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())") \
-v /tmp:/tmp \
--net cp-all-in-one_default \
puckel/docker-airflow webserver

docker exec -it airflow sh -c "airflow variables --import /airflow_env.json"

sleep 5

echo "You can now visit http://localhost:8080 to see the DAG"
# setup spark container 

cd spark

docker-compose build  --build-arg PATH_TO_SPARK_JAR=$(basename $JAR_DEST)
docker-compose up -d

# Now let's wait until airflow has reached the spark execution state
comm_file="/tmp/spark_command_ready"
until [ -f $comm_file ]
do
    echo "waiting $comm_file to exist. Sleeping 10s"
    sleep 10
done

# Execute command provided by airflow
docker exec -d stream_lib_container_master spark-submit --master spark://spark:7077 $(cat $comm_file)

# Execution of the container will take place in the DAG
echo "E2E run initialization completed..."