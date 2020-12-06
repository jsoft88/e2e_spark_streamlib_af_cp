#!/bin/sh

set -e

echo "==========================================================================================="
echo "Clearing the e2e run"
echo "==========================================================================================="

cd spark && docker-compose down

docker container stop airflow && docker container rm airflow

cd ../cp-all-in-one/cp-all-in-one && docker-compose down

[ -f /tmp/spark_command_ready ] && rm -f /tmp/spark_command_ready

echo "Everything clean now.. you can re-rerun everything by running the run.sh script again :)"