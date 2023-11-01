#!/bin/bash

# Usage: ./flash-esp.sh /dev/espport wifi_ssid wifi_password [mqtt_username mqtt_password]
# This script flashes the ESP with the Mosquitto demo firmware and sends the configuration data via USB

# Exit script on error
set -e

# Check if any argument is missing
if [[ -z "$1" || -z "$2" || -z "$3" ]]
then 
  echo "Usage: $0 /dev/espport wifi_ssid wifi_password [mqtt_username mqtt_password]"
  exit 1
fi

echo "Checking dependencies"

# Variable that holds missing dependencies
dependencies=""

# Check if the esptool command is not found
if [[ -z "$(command -v esptool)" ]]
then
  dependencies+="esptool "
fi

# Check if the wget command is not found
if [[ -z "$(command -v wget)" ]]
then
  dependencies+="wget "
fi

# Check if any dependencies are missing
if [[ -n "$dependencies" ]]
then
  echo "Installing dependencies"
  apt -y install $dependencies
fi

echo ""
echo "Downloading ESP32 binary"

# Download ESP32 binary to firmware.bin
wget "https://drive.google.com/uc?export=download&id=1BweSlzOMd1uK7cf3e-jm62O6GCs0AYiL" -O firmware.bin

echo ""
echo "Flashing ESP32 binary"
echo "If esptool is stuck on connecting, reset the ESP into bootloader mode, by holding \"BOOT\" and pressing \"EN\""
sleep 5

# Read the esp port argument into a variable
esp_port="$1"

# Flash firmware.bin to esp
esptool --chip esp32 --port "$1" --baud 460800 --before default_reset --after hard_reset write_flash 0x0 firmware.bin

echo "Flashing complete"

# Save SSID and WiFi password in variables
wifi_ssid="$2"
wifi_password="$3"

echo ""
echo "Setting up connection to ESP32"

# Setup serial port with baud rate 9600 and raw data
stty -F "$esp_port" 9600 raw -echo

# Reroute incoming data from the esp into a temporary file
rm -f /tmp/esplog
cat "$esp_port" > /tmp/esplog &

# Cleanup when script exits
trap 'kill $(jobs -p); rm -f /tmp/esplog' EXIT 

echo ""
echo "Reset the ESP32 now by pressing the \"EN\" button"

# Wait for the esp to be reset
while true
do
  output=$(tail -n 1 /tmp/esplog | tr -d '\0')

  if [[ "$output" == *"Input the WiFi-SSID"* ]]
  then
    break
  fi

  sleep 0.5
done

echo ""
echo "Sending WiFi and MQTT information ..."

# Send SSID and WiFi password to the esp
echo "$wifi_ssid" > $esp_port
echo "$wifi_password" > $esp_port

# Get IPv4 of broker
broker_ip=$(hostname -I | cut -d " " -f1)

mqtt_username=""
mqtt_password=""

if [[ -n "$4" && -n "$5" ]]
then
  mqtt_username="$4"
  mqtt_password="$5"
fi

# Send mosquitto info to ESP
echo "$broker_ip" > $esp_port
echo "1883" > $esp_port
echo "esp/demo" > $esp_port
echo "$mqtt_username" > $esp_port
echo "$mqtt_password" > $esp_port

# Loop that checks connection status of ESP
while true
do
  output=$(tail -n 3 /tmp/esplog | tr -d '\0')

  if [[ "$output" == *"Could not connect to the MQTT broker"* ]]
  then
    echo ""
    echo "The ESP32 could not connect to the MQTT broker. Make sure it is running."
    exit 1
  elif [[ "$output" == *"Could not connect to the WiFi network"* ]]
  then
    echo "The ESP32 could not connect to WiFi."
    exit 1
  elif [[ "$output" == *"Connected to MQTT broker"* ]]
  then
    echo "ESP successfully connected to WiFi and to the MQTT broker."
    break
  fi
  
  sleep 0.5
done

echo "Finished setting up the ESP32."
