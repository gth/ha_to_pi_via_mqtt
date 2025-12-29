#!/bin/bash

# Update hostname and MQTT user credentials to match your environment.

echo "Subscribed to 'test' on broker 'homeassistant'..."
mosquitto_sub -h homeassistant -t test -u mqtt-user -P mypassword
