#!/bin/bash

# Usage: test_01.sh [user password]
# Subscribes to MQTT topic "test" on local broker

set -e

auth=""

if [[ -n "$1" && -n "$2" ]]
then
    auth="-u $1 -P $2"
fi

mosquitto_sub -h localhost -t test $auth
