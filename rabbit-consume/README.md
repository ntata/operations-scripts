# Script to VIEW or DRAIN messages from a queue
Env variable DRAIN_QUEUE determines whether to only read messages from the queue or consume them.

## Prerequisites
- ssh
- rabbitmq node name

## Logic:
viewMessages() method calls channel.consume() but explicitly sends a negative acknowledgment for the
messages read making rabbit requeue messages.

drainQueue() method calls channel.consume() and sends a positive acknoeldgement for every message that
was read there by marking a successful consumption of message.

Both the methods read the message and print it out to stdout.

## Usage:
connect to rabbitmq on port 5672 on localhost
1. set values in env file
2. ``` source env ```
3. python consume-to-stdout.py
