#!/bin/bash
if [[ -z "$1" || -z "$2" || -z "$3" ]]
then 
  echo "Usage: $0 /dev/espport wifi_ssid wifi_password [mqtt_username mqtt_password]"
  exit 1
fi

set -e

esp_port="$1"
wifi_ssid="$2"
wifi_password="$3"

echo "Setting up connection to ESP32"

# Setup serial port
stty -F "$esp_port" 9600
stty -F "$esp_port" raw

# Reroute incoming data from the esp into a temporary file
rm -f /tmp/esplog
cat "$esp_port" > /tmp/esplog &
trap 'kill $(jobs -p); rm -f /tmp/esplog' EXIT # Cleanup when script exits

echo ""
echo "Reset the ESP32 now by pressing the "EN" button"

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

echo "$wifi_ssid" > $esp_port
echo "$wifi_password" > $esp_port

# Loop that checks connection status of the ESP
while true
do
  output=$(tail -n 3 /tmp/esplog | tr -d '\0')

  if [[ "$output" == *"Could not connect to the WiFi network"* ]]
  then
    echo ""
    echo "The ESP could not connect to the wifi, please check your credentials and try again."
    exit 1
  fi

  if [[ "$output" == *"Connected to the WiFi network"* ]]
  then
    echo ""
    echo "ESP successfully connected to WiFi."
    break
  fi

  sleep 0.5
done

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
    echo "The ESP32 could not connect to the MQTT broker."
    exit 1
  fi

  if [[ "$output" == *"Connected to MQTT broker"* ]]
  then
    echo ""
    echo "ESP successfully connected to the MQTT broker."
    break
  fi
  
  sleep 0.5
done

while true
do
  read -p "Message: " message
  mosquitto_pub -h localhost -t esp/demo -m "$message" -u "$mqtt_username" -P "$mqtt_password"
done
