# Trigger shell scripts on a (remote) Raspberry Pi from Home Assistant using MQTT

I stumbled across some tasty morsels of relevant information and figured I'd present them here.
My aim is to document what I found in a logical way so others might follow the sequence more easily.

While I was searching for this information, various guides fell short for what I needed:
* How to install the MQTT broker on Home Assistant itself is described **many** times, but rarely goes further.
  * (this makes sense, since MQTT can be used for MANY things)
* Those who wanted to trigger tasks on remote Raspberry Pi machines were usually guided towards SSH.
  * (which is fine if that's one's preference, but the MQTT method was not presented as a viable alternative)
* When MQTT was mentioned, Python would often be used as a one-word solution and no further explanation.
  * (and once again, Python is fine if you prefer it, but shell scripts were rarely mentioned)
* Some guides eventually mention Pi's MQTT client packages, but didn't explain how to use them.

Lastly, I will point out the subscribe/publish cycle is explained well in many MQTT guides - this simplicity is its strength!

# Assumptions
These instructions assume the reader:
* Is using a hostname of **homeassistant** for HA - if not, replace where necessary; 
* Has already installed the MQTT broker on their HA instance;
* Configured a specific user for MQTT in HA, e.g. **mqtt-user**;
* Already has a Raspberry Pi up and running and connecting via SSH; 
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

## Sending your first message
To fire off a message, in the top section **Publish a packet**, enter a **Topic** value of `garage/door` - this must match what we typed previously.
In the payload field, type some plain text and click **Publish** - you'll then see your message appear in the listening section below.
While this may seem overly simplistic, it actually proves the enter cycle is working behind the scenes. You're ready to proceed.

> [!TIP]
> If this doesn't work or you can't see MQTT in **Devices & services**, you'll need to follow one of the many guides to install it and/or possibly restart HA.

# Getting the Raspberry Pi on the MQTT bandwagon
On the remote Rasperry Pi, install the required MQTT client software -
```sh
sudo apt-get install mosquitto-clients
```
Once complete, use the command below on the Pi to **subscribe** to topic **test** on the HA broker -
```sh
mosquitto_sub -h homeassistant -t test -u mqtt-user -P mypassword
```
This command will be an amazing example of... nothing.  Because there's no messages to receive yet!
Leave this SSH session - we'll come back to it shortly - and start another session.

# Sending your second message
Let's publish a message using the command below (note that is actually a different command) -
```sh
mosquitto_pub -h homeassistant -t test -m "Hello, MQTT!" -u mqtt-user -P mypassword
```

Something has happened!  Go back to the SSH session where you subscribed to the **test** topic and you'll see that a message has appeared:
```
$ mosquitto_sub -h homeassistant -t test -u mqtt-user -P mypassword
Hello, MQTT!
```

