#!/bin/bash

# Usage: test_01.sh [user password]
# Subscribes to MQTT topic "test" on local broker

# End script on error
set -e

# Variable that holds arguments for the MQTT authentication
auth=""

# Check if username and password where supplied
if [[ -n "$1" && -n "$2" ]]
then
    # Fill variable auth with username and password arguments
    auth="-u $1 -P $2"
fi

# Subscribe to the "test" topic running on the local system
mosquitto_sub -h localhost -t test $auth
