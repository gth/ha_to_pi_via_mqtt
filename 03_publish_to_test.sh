#!/bin/bash 

# Update hostname and MQTT user credentials to match your environment.

echo "Sending hello message to topic 'test' on broker 'homeassistant'..."
mosquitto_pub -h homeassistant -t test -m "Hello, MQTT!" -u mqtt-user -P mypassword
