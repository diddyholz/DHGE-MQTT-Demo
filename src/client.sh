#!/bin/bash

# This script installs mosquitto clients for Linux and macOS platform.

set -e

uname="$(uname -s)"

echo "Checking dependencies ..."

if [[ -n "$(command -v mosquitto_pub)" ]]
then
  echo "Dependency already installed"
  exit 0
fi

echo "Installing dependencies"

if [[ "$uname" == "Linux"* ]]
then
  apt install -y mosquitto-clients
elif [[ "$uname" == "Darwin"* ]]
then
  brew install mosquitto
fi

echo "Dependencies installed"
