#!/bin/bash

# Usage: server.sh [username password]
# Installs the mosquitto server, creates a config and if specified, a password file.

# Exit script on error
set -e

echo ""
echo "Checking dependencies ..."

# Check if the mosquitto command is not found
if [[ -z "$(command -v mosquitto)" ]]
then
  echo "Installing dependencies"
  apt install -y mosquitto
fi

echo ""
echo "Creating mosquitto config"

# Create general config for mosquitto
# Listen on port 1883 for all IPv4 addresses
echo "listener 1883 0.0.0.0" > /etc/mosquitto/conf.d/demo.conf

# Check if a username and password where supplied
if [[ -n "$1" && -n "$2" ]]
then
  # Create password file for mosquitto
  echo -e "$2\n$2" | mosquitto_passwd -c /etc/mosquitto/demopwfile.txt "$1" > /dev/null
  echo "password_file /etc/mosquitto/demopwfile.txt" >> /etc/mosquitto/conf.d/demo.conf
else
  # If no authentication details where supplied, allow unauthenticated users
  echo "allow_anonymous true" >> /etc/mosquitto/conf.d/demo.conf
fi

echo ""
echo "Restarting mosquitto service"

# Restart mosquitto service to reload the config
systemctl restart mosquitto

echo ""
echo "Finished setting up the mosquitto broker."
