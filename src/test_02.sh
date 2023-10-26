#!/bin/bash

# Usage: ./test_02.sh IP [user password]
# Sends messages to MQTT Broker on topic "test"

if [[ -z $1 ]]
then
    echo "Usage: $0 IP [user password]"
fi

while true:
    mosquitto_pub -h $1 -t test -m "TEST" -u $2 -P $3
    sleep 1
done
