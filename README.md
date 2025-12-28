# From Home Assistant to Raspberry Pi via MQTT
Trigger a shell script on a (remote) Raspberry Pi from Home Assistant, using MQTT messaging.

# Background
While searching to achieve the desired goal described above, I kept finding gaps in the discussions/guides/videos...
* How to install the MQTT broker on the Home Assistant instance itself is described **many** times, but rarely goes further.
* Those who wanted to trigger tasks on remote Raspberry Pi machines were usually guided towards SSH.
* When MQTT was referred to, often Python would be mentioned as a one-word solution with no further explanation given.
* Some eventually mentioned the MQTT client packages for the Pi, but didn't explain much further.
* The subscribe/publish cycle is explained well by a number of people - this simplicity is its strength!

I stumbled across some tasty morsels of relevant information and figured I'd present them one place.
My aim is also to document what I've found in a logical way so that others might follow the sequence more easily.

# Assumptions
These instructions assume the reader:
* Has already installed the MQTT broker on their HA instance;
* Is familiar with Linux shell scripting or at least willing to have a go;
* Is NOT trying to communicate with a Raspberry Pi their HA instance is actually running on (which would be weird); and,
* Will amend sample credentials to something much more secure in their environment!

# Installation
As I'm merely storing helpful scripts here for reference, there's no bundle of files to download, nor is there any automated process in this repository that will 'just do it' for you; this is a "hands-on" guide.

# What is MQTT?
MQTT can be thought of as "message queues" managed by a central broker (that broker running on Home Assistant, in our case).
Each queue is called a 'topic'.  With the correct permissions, any device can **publish** a message to a topic.
Similarly, any device can also **subscribe** to a topic, and thus receive any messages that published to it.

# Checking HA's MQTT Broker
In **Home Assistant**, go to **Settings** / **Devices & Services** / **MQTT** / click the **cog icon** to display the **MQTT settings** panel. 
Disregard the panel title - this is actually a useful test area, which we can use to verify the broker is working properly.

## Listen to a topic
At the bottom of the panel, enter the **Topic to subscribe to** as `garage/door` and then click the **Start listening** link.
At this point, any MQTT messages for the garage/door topic sent from any device will be displayed at the bottom of the screen.

## Publish a packet
To fire off a message, in the top section enter a **Topic** value of `garage/door` - this must match what we typed previously.
In the payload section, type any text and then click **Publish** - you'll then see the message appear in the listening section.
While this may seem overly simplistic, it proves the enter cycle is working behind the scenes and you're ready to proceed.

<sub>If this doesn't work or if you can't see MQTT in your Devices & services area, you'll need to follow one of the many guides to install it and/or possibly restart HA.</sub> 


# Getting the Raspberry Pi on the MQTT bandwagon
On the remote Rasperry Pi, install the required MQTT client software -
```
sudo apt-get install mosquitto-clients
```
