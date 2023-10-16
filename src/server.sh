#!/bin/bash

# Usage: server.sh [username password]
#
# Installs the mosquitto server, creates a config and if specified, a password file.
set -e

echo ""
echo "Checking dependencies ..."

# Check required dependencies
if [[ -z "$(command -v mosquitto)" ]]
then
  echo "Installing dependencies"
  apt install -y mosquitto
fi

echo ""
echo "Creating mosquitto config"

# Create general config for mosquitto
echo "listener 1883 0.0.0.0" > /etc/mosquitto/conf.d/esp.conf

# Create password file for mosquitto if needed
if [[ -n "$1" && -n "$2" ]]
then
  echo -e "$2\n$2" | mosquitto_passwd -c /etc/mosquitto/esppwfile.txt "$1" > /dev/null
  echo "password_file /etc/mosquitto/esppwfile.txt" >> /etc/mosquitto/conf.d/esp.conf
else
  echo "allow_anonymous true" >> /etc/mosquitto/conf.d/esp.conf
fi

echo ""
echo "Restarting mosquitto service"
systemctl restart mosquitto

echo ""
echo "Finished setting up the mosquitto broker."
