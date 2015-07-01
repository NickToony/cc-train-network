# ComputerCraft Train Network

A collection of LUA scripts that combine to create a fully automated train network in Minecraft, using ComputerCraft and RailCraft. The intention is that users may request a train, set a location, and the train will calculate a route to that location while enforcing a block-based signaling system.

This is a rewrite of my original system, which I lost half the code for. This time the code will hopefully be better structured and easier to maintain. It's a work in progress, and **does not yet work**.

## Current Features
Basic OS that updates itself, pulls down dependencies and responds to global commands.

Networking layer that provides reliable communication

Train pathfinding algorithm

Holder funtionality

More soon...

#Networking

The networking API provided is an implementation of the Distance Vector algorithm for routing, and a TCP-inspired hand-shake for packet confirmation. This network layer deals with the two main issues with ComputerCraft wireless networking:

* Wireless modems have a limited broadcast range
* There's two guarantee that a broadcast was received

Packets sent via the network API will use the shortest route through the network to reach its destination, with messages transmitting through neighbours, eliminating the broadcast range issue. Every node will also return a confirmation packet, and retry sending the packet if this confirmation is not received.


# Quick Documentation

**OS**

Dubbed the "train OS", the basic set of scripts provides shared funcitonality for networking, data operations and updating. Any time a terminal is rebooted, it will update all its core scripts, and fetch the required dependencies.

**Trains**

Trains are automatically maintained by being refilled with fuel and water as needed. Their location is tracked *roughly* based on their last known destination and target destination. Using the train's location data, we can make a good assumption about which part of the network each train occupies, and prevent other trains entering that block. This simple block system prevents trains colliding.

**Holders**

Holders are effectively dumb stations. Their only role is to hold idle trains, and manage their fuel/water needs.

**Stations**

Stations are a bit smarter, and will allow users to interact with them in order to request trains or view estimated arrival times. They hold trains until the next block/station on their route is free.

**Controller**

The controller manages the network. It tracks locations of trains, requests from users, train fuel/water levels, and communicates with all other components by sending instructions.

**Master**

The master terminal is a way to override the system and manually run commands. Because the controller is so vital to the network functionality, it cannot be interrupted for any reason. Hence, the master is introduced as a non-vital terminal that allows a user to send commands out to all other terminals at once.

# Installation
A quick copy&paste will install the base OS, and allow you to configure the type of sytem it is. Check the install.lua script.

Type `lua` into a ComputerCraft terminal, paste the line, and hit enter. It will then boot into the OS.

More instructions will follow when this actually works again.
