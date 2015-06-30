# ComputerCraft Train Network

A collection of LUA scripts that combine to create a fully automated train network. The intention is that users may request a train, set a location, and the train will calculate a route to that location while working off a block-based signaling system.

This is a rewrite of my original system, which I lost half the code for. This time the code will hopefully be better structured and easier to maintain. It's a work in progress, and does not yet work.

# OS
Dubbed the "train OS", the basic set of scripts provides shared funcitonality for networking, data operations and updating. Any time a terminal is rebooted, it will update all its core scripts, and fetch the required dependencies.
# Trains
Trains are automatically maintained by being refilled with fuel and water as needed. Their location is tracked *roughly* based on their last known destination and target destination.
# Blocks
Using the train's location data, we can make a good assumption about which part of the network each train occupies, and prevent other trains entering that block. This simple block system prevents trains colliding.
# Holders
Holders are effectively dumb stations. Their only role is to hold idle trains, and manage their fuel/water needs.
# Stations
Stations are a bit smarter, and will allow users to interact with them in order to request trains or view estimated arrival times. 
# Controller
The controller manages the network. It tracks locations of trains, requests from users, train fuel/water levels, and communicates with all other components by sending instructions.
# Master
The master terminal is a way to override the system and manually run commands. Because the controller is so vital to the network functionality, and all  terminals are used for wireless communication purposes, the master is a non-vital terminal that allows a user to send commands out to all other terminals at once.
# Network Routing
Because ComputerCraft's wireless protocols are so basic, a networking library was developed to introduce reliable wireless transmission. A key requirement of this library was to allow routing of messages through nearby terminals so that packages can reach terminals beyond the current wireless range. Additional features include packet handshake (ensuring all messages reach their destination) and shortest path routing. If a terminal goes down for any reason, the routing algorithm can recover and choose an alternative route.

# Installation
A quick copy&paste will install the base OS, and allow you to configure the type of sytem it is. Check the install.lua script.

Type `lua` into a ComputerCraft terminal, paste the line, and hit enter. It will then boot into the OS.
