#!/bin/bash

# Update hostname and MQTT user credentials to match your environment.

# Configuration
MQTT_BROKER="homeassistant"             # MQTT server
MQTT_TOPIC="garage/door"                # Topic to subscribe to
CLIENT_ID="sub_client_$(date +%s)"      # A unique client ID

echo "Subscribing to topic: $MQTT_TOPIC on broker: $MQTT_BROKER"

# Subscribe to the topic and pipe the output to a while loop
mosquitto_sub -u mqtt-user -P mypassword -h "${MQTT_BROKER}" -t "${MQTT_TOPIC}" -i "${CLIENT_ID}" |
    while read -r payload ; do
        echo "Received message: $payload"

        if [ "$payload" == "OPEN" ]; then
            echo "Commands below will OPEN the garage door."
            # (insert commands here)

        elif [ "$payload" == "CLOSE" ]; then
            echo "Commands below will CLOSE the garage door."
            # (insert commands here)

        else
            echo "Payload not recognised ($payload)."
        fi
    done
echo "-- Script terminated."
