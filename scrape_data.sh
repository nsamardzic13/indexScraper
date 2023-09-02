#!/bin/bash

## note - script must be executed from scrapy project dir

# fail on err
set -eo pipefail

source ../.venv/bin/activate

EPOCH=$(date +%s)

WORKDIR=$(dirname $(pwd))
DATADIR="${WORKDIR}/data"
LOGDIR="${WORKDIR}/logs"

# list of PIDs
PIDS=()

## crawl cars
for TYPE in cars apartments houses
do 
    DATA_FILE="${DATADIR}/${TYPE}-${EPOCH}.json"
    LOG_FILE="${LOGDIR}/${TYPE}-${EPOCH}.log"
    # execute crawl
    scrapy crawl $TYPE -a mode=$1 -O $DATA_FILE --logfile $LOG_FILE 2> $LOG_FILE &

    # add pid
    PIDS+=($!)
done

# wait for every pid to finish
for PID in "${PIDS[@]}"
do
    wait $PID
done

echo "Crawling completed"

# do the transformation - from main dir 
cd ..

python transform_load.py