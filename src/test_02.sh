#!/bin/bash

# Usage: ./test_02.sh IP [user password]
# Sends messages to MQTT Broker on topic "test"

if [[ -z "$1" ]]
then
    echo "Usage: $0 IP [user password]"
fi

set -e

auth=""

if [[ -n "$2" && -n "$3" ]]
then
    auth="-u \"$2\" -P \"$3\""
fi

while true
do
    mosquitto_pub -h $1 -t test -m "TEST" $auth
    sleep 1
done
