#!/bin/bash

# Usage: test_01.sh [user password]
# Subscribes to MQTT topic "test" on local broker

mosquitto_sub -h localhost -t test -u $1 -P $2
