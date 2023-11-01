#!/bin/bash

# Usage: ./test_02.sh IP [user password]
# Sends messages to MQTT Broker on topic "test"

# Check if all arguments are satisfied
if [[ -z "$1" ]]
then
    echo "Usage: $0 IP [user password]"
    exit 1
fi

# End script on error
set -e

# Variable that holds arguments for the MQTT authentication
auth=""

# Check if username and password where supplied
if [[ -n "$2" && -n "$3" ]]
then
    # Fill variable auth with username and password arguments
    auth="-u $2 -P $3"
fi

# Infinite loop
while true
do
    # Publish a message in the "test" topic
    mosquitto_pub -h $1 -t test -m "TEST" $auth
    sleep 1
done
