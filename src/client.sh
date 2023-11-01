#!/bin/bash

# This script installs mosquitto clients for Linux and macOS platform.

# Exit script on error
set -e

# Get OS name
uname="$(uname -s)"

echo "Checking dependencies ..."

# Check if the mosquitto_pub command is found
if [[ -n "$(command -v mosquitto_pub)" ]]
then
  echo "Dependency already installed"
  exit 0
fi

echo "Installing dependencies"

# Check if running on Linux or macOS
if [[ "$uname" == "Linux"* ]]
then
  apt install -y mosquitto-clients
elif [[ "$uname" == "Darwin"* ]]
then
  brew install mosquitto
fi

echo "Dependencies installed"
