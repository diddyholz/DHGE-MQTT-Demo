#!/bin/bash

# Usage: ./setup.sh /dev/espport [username password]
#
# Installs the required dependencies (mosquitto, mosquitto-clients, wget & esptool), flashes the ESP, 
# creates a mosquitto config and if specified, a password file for mosquitto.

if [[ -z "$1" ]]
then 
  echo "Usage: $0 /dev/espport [username password]"
  exit 1
fi

set -e

echo "Adding user to dialout group"
usermod -a -G dialout $USER

echo ""
echo "Installing dependencies"

# Check required dependencies
dependencies=""

if [[ -z "$(command -v mosquitto)" ]]
then
  dependencies+="mosquitto "
fi

if [[ -z "$(command -v mosquitto_pub)" ]]
then
  dependencies+="mosquitto-clients "
fi

if [[ -z "$(command -v esptool)" ]]
then
  dependencies+="esptool "
fi

if [[ -z "$(command -v wget)" ]]
then
  dependencies+="wget "
fi

# Install dependencies
if [[ -n "$dependencies" ]]
then
  apt -y install $dependencies
fi

echo ""
echo "Downloading ESP32 binary"

# Download ESP32 binary
wget "https://drive.google.com/uc?export=download&id=1cg_JMuruzXmbdTttGVZK3J5zqH9RuYsL" -O firmware.bin

echo ""
echo "Flashing ESP32 binary"
echo "If esptool is stuck on connecting, reset the ESP into bootloader mode, by holding \"BOOT\" and pressing \"EN\""
sleep 5

# Flash binary
esptool --chip esp32 --port "$1" --baud 460800 --before default_reset --after hard_reset write_flash 0x0 firmware.bin

echo ""
echo "Creating mosquitto config"

# Create general config for mosquitto
echo "listener 1883 0.0.0.0" > /etc/mosquitto/conf.d/esp.conf

# Create password file for mosquitto if needed
if [[ -n "$2" && -n "$3" ]]
then
  echo -e "$3\n$3" | mosquitto_passwd -c /etc/mosquitto/esppwfile.txt "$2"
  echo "password_file /etc/mosquitto/esppwfile.txt" >> /etc/mosquitto/conf.d/esp.conf
else
  echo "allow_anonymous true" >> /etc/mosquitto/conf.d/esp.conf
fi

echo ""
echo "Restarting mosquitto service"
systemctl restart mosquitto

echo ""
echo "Finished setting up the mosquitto broker and ESP32."
echo "You might need to log out and log back in to access serial ports."

