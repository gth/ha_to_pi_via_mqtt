# Trigger remote Pi script from Home Assistant via MQTT

> _A guide to opening a garage door using Home Assistant, after installing the MQTT integration._

I stumbled across some tasty morsels of relevant information and figured I'd present them here.
The aim is to document what I found in a logical way so others might follow the sequence more easily.

While I was searching for this information, various guides fell short for what I needed:
* How to install the MQTT broker on Home Assistant itself is described **many** times, but rarely goes further.
  * (this makes sense, since MQTT can be used for MANY things)
* Those who wanted to trigger tasks on remote Raspberry Pi machines were usually guided towards SSH.
  * (which is fine if that's one's preference, but the MQTT method was not presented as a viable alternative)
* When MQTT was mentioned, Python would often be used as a one-word solution and no further explanation.
  * (and once again, Python is fine if you prefer it, but shell scripts were rarely mentioned)
* Some guides eventually mention Pi's MQTT client packages, but didn't explain how to use them.

Lastly, I will point out the subscribe/publish cycle is explained well in many MQTT guides - this simplicity is its strength!<br />
These instructions assume the reader -
* Is using a hostname of **homeassistant** for HA - if not, replace where necessary; 
* Has already installed the MQTT broker on their HA instance;
* Configured a specific user for MQTT in HA, e.g. **mqtt-user**;
* Already has a Raspberry Pi up and running and connecting via SSH; 
* Is familiar with Linux shell scripting or at least willing to have a go;
* Is NOT trying to communicate with a Raspberry Pi their HA instance is actually running on (which would be weird); and,
* Will amend sample credentials to something much more secure in their environment!


# What is MQTT?
MQTT can be thought of as "message queues" managed by a central broker (that broker running on Home Assistant, in our case).
Each queue is called a 'topic'.  With the correct permissions, any device can **publish** a message to a topic.
Similarly, any device can also **subscribe** to a topic, and thus receive any messages that published to it.

In **Home Assistant** go to  **Settings**  then  **Devices & Services**  and find the  **MQTT**  integration.

<img width="520" height="450" alt="image" src="https://github.com/user-attachments/assets/8d7aa2fc-05c0-4a9f-b29f-5022c5884138" />

> [!TIP]
> If you can't see MQTT in **Integrations**, you'll need to follow one of the many guides to install it and/or possibly restart HA.

After opening the MQTT integration, click the **⚙ cog icon** to display the **MQTT settings** panel -

<img width="383" height="445" alt="image" src="https://github.com/user-attachments/assets/c647371e-803e-4eb6-8384-91fa4b08c159" />

The panel title is a bit misleading - this is actually a useful testbed and shows how the broker works; see flow diagram below)


## Listening to a topic
At the bottom of the panel, enter the **Topic to subscribe to** as `garage/door` and then click the **Start listening** link.
At this point, any MQTT messages for the garage/door topic sent from any device will be displayed at the bottom of the screen.

## Sending your first message

<img width="383" height="65" alt="image" src="https://github.com/user-attachments/assets/e1c6d1ef-8009-476d-8acf-6901c16bfe17" />

To fire off a message, in the top section **Publish a packet**, enter a **Topic** value of `garage/door` - this must match what we typed previously.
In the payload field, type some plain text and click **Publish** - you'll then see your message appear in the listening section below.
While this may seem overly simplistic, it actually proves the enter cycle is working behind the scenes. You're ready to proceed.

## On the Raspberry Pi
On the remote Rasperry Pi, install the required MQTT client software -
```sh
sudo apt-get install mosquitto-clients
```
Once complete, use the command below on the Pi to **subscribe** to topic **test** on the HA broker -
```sh
mosquitto_sub -h homeassistant -t test -u mqtt-user -P mypassword
```
This command will be an amazing example of... nothing.  Because there's no messages to receive yet!<br />
Leave this SSH session - we'll come back to it shortly - and start another session.

## Sending your second message
<img width="383" height="65" alt="image" src="https://github.com/user-attachments/assets/62d815ea-da28-4117-9791-28f6fee89b28" />

Let's publish a message using the command below (while it looks similar, it is actually a different command) -
```sh
mosquitto_pub -h homeassistant -t test -m "Hello, MQTT!" -u mqtt-user -P mypassword
```

Go back to the SSH session where you subscribed to the **test** topic and you'll see a message has appeared:
```
$ mosquitto_sub -h homeassistant -t test -u mqtt-user -P mypassword
Hello, MQTT!
```

## Listening in a loop

Assuming you've already got a series of commands that "do something", let's get down to the useful part.
We're going to need a "subscribe" script that can 'read' the incoming payload and decide what to do.
After processing a payload message, the script needs to return to the listening state, awaiting the next message.

Create a new script `nano mqtt_receiver.sh` and paste the code below:

```sh
#!/bin/bash

# Configuration
MQTT_BROKER="homeassistant"          # MQTT server
MQTT_TOPIC="garage/door"             # Topic to subscribe to
CLIENT_ID="sub_client_$(date +%s)"   # A unique client ID

echo "Subscribing to topic: $MQTT_TOPIC on broker: $MQTT_BROKER"

# Subscribe to the topic and pipe the output to a while loop
mosquitto_sub -u mqtt-user -P mypassword -h "${MQTT_BROKER}" -t "${MQTT_TOPIC}" -i "${CLIENT_ID}" |
  while read -r payload ; do
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
```

> [!NOTE]
> Despite searching for it, I cannot find the original source for this shell script. <br />All credit goes to the original author - my changes were minimal.

Once you have saved the shell script, make it executable using `chmod u+x mqtt_receiver.sh` and then run it via `./mqtt_receiver.sh`
Just like the earlier subscribe script, it will wait until it receives a message before doing anything...  

## Trigger the script via MQTT (aka 'Sending your third message')
In a new SSH session enter the command below to publish the message that our script is expecting:
```sh
mosquitto_pub -h homeassistant -t 'garage/door' -m "OPEN" -u mqtt-user -P mypassword
```

...and if we go back to the first SSH session, we can see the relevant section of the script was triggered:
```sh
$ ./mqtt_receiver.sh
Subscribing to topic: garage/door on broker: homeassistant
Commands below will OPEN the garage door.
```

# From dashboard to garage door
<img width="383" height="65" alt="image" src="https://github.com/user-attachments/assets/7d74a77b-6139-4c4f-a431-845598427b45" />

Home Assistant supports many possible methods to publish an MQTT message.  For example, an automation script could include it as part of 
a series of commands.  A more simple example, shown below, involves publishing an MQTT message directly from a dashboard button.
Add the code below to one of your dashboard buttons [^1] -
```yaml
    tap_action:
      action: call-service
      service: mqtt.publish
      service_data:
        topic: garage/door
        payload: OPEN
```
[^1]: https://community.home-assistant.io/t/create-a-button-to-publish-to-mqtt/239077/6

Once added, check your SSH session.  The dashboard button should have  triggered the listening script on the Pi.


# Adding resilience
Throughout this guide, the listening component of the process has been running interactively in our SSH session.  
For a much more reliable solution, this script should be running all the time as a 'service'. 
The steps below go through this process:

1. Copy the listening script to a central location so we know where it is.
```sh
sudo cp mqtt_receiver.sh /usr/local/bin/
```
2. Create the service defintion.  You'll need root permissions to create a script using the
following command: `sudo nano /etc/systemd/system/mqtt_listener.service` then paste the settings below.

```ini
[Unit]
Description=MQTT subscriber script to open and close the garage door
After=network-online.target

[Service]
ExecStart=/usr/local/bin/mqtt_receiver.sh
Type=simple 
Restart=always

[Install]
WantedBy=multi-user.target
```

3. The following series of commands will get the service up and running
```sh
sudo systemctl daemon-reload
sudo systemctl start mqtt_listener.service
sudo systemctl enable mqtt_listener.service
sudo systemctl status mqtt_listener.service
```

4. Provided everything went okay, you should see a status result similar to the one shown below:
```
$ sudo systemctl status mqtt_listener.service

● mqtt_listener.service - MQTT subscriber script to open and close the garage door
     Loaded: loaded (/etc/systemd/system/mqtt_listener.service; enabled; preset: enabled)
     Active: active (running) since Mon 2025-12-29 11:02:03 AEDT; 3s ago
 Invocation: 0e2dcc2a7cff492f9cfc7aad5ae1621c
   Main PID: 4529 (mqtt_receiver.s)
      Tasks: 3 (limit: 3920)
        CPU: 30ms
     CGroup: /system.slice/mqtt_listener.service
             ├─4529 /bin/bash /usr/local/bin/mqtt_receiver.sh
             ├─4531 mosquitto_sub -u mqtt-user -P mypassword -h homeassistant -t garage/door -i sub_client_1766966523
             └─4532 /bin/bash /usr/local/bin/mqtt_receiver.sh

Dec 29 11:02:03 pi systemd[1]: Started mqtt_listener.service - MQTT subscriber script to open and close the garage door.
Dec 29 11:02:03 pi mqtt_receiver.sh[4529]: Subscribing to topic: garage/door on broker: homeassistant
```

This same status command can be used to display any message the script would normally display during an interactive SSH session.

Fin.
