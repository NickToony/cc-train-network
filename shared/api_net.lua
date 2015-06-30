-- Global variables
QUERY_TIME = 0 -- frequency to broadcast information
STACK = { } -- stack of messages to send
TIMEOUT = api_os.calcTime(3)
CURRENT_ID = 5


-- Prepare method, should be called before doing any sort of networking
function prepare()
    return rednet.open("back")
end

-- handleMesssage
--[[
	A static method, should be called to receieve messages. It will deal with the parsing of the message and such,
	and return a Message object on success. If it's a networking message, it'll handle it itself
]]
function handleMessages()
    -- First, check if we need to broadcast info
    if math.abs(QUERY_TIME - os.time()) > api_os.calcTime(60) then
        inst_Table:sendQuery()
        QUERY_TIME = os.time()
    end

    handleStack()

    local senderId, message, protocol = rednet.receive(0)

    if message == nil then
        return nil
    end

    local inst_Message = Message.new()
    inst_Message:parse(message)
    --inst_Message:setSender(senderId)

    if inst_Message:getType() == "query" then
        -- read it
        inst_Table:readQuery(inst_Message)
        -- print "HANDLE QUERY"
    elseif inst_Message:getType() == "ack" then
        if tonumber(inst_Message:getTarget()) == os.getComputerID() then
            removeStack(inst_Message:getID()) -- don't send that message again
        else
            inst_Message:sendUnreliable()
        end
    else
        if (tonumber(inst_Message:getID()) > -1) then
            if tonumber(inst_Message:getTarget()) == os.getComputerID() then

                local newMessage = Message.new()
                newMessage:setType("ack")
                newMessage:setTarget(inst_Message:getSender())
                newMessage:setSender(os.getComputerID())
                newMessage:setNetwork("default")
                newMessage:setID(inst_Message:getID())
                newMessage:sendUnreliable()

                -- Return to main class
                return inst_Message

            else
                -- forward to someone else
                inst_Message:sendUnreliable()
            end
        end
    end

    return nil
end
function handleStack()
    local i
    for i = 1, table.getn(STACK) do
        local stackedMessage = STACK[i]
        if (math.abs(os.time() - stackedMessage.time) > TIMEOUT) then
            stackedMessage:send()
        end
    end
end
function removeStack(id)
    local i
    for i = 1, table.getn(STACK) do
        local stackedMessage = STACK[i]
        if tostring(stackedMessage:getID()) == tostring(id) then
            table.remove(STACK, i)
            return
        end
    end
end




StackedMessage = {}
StackedMessage.__index = StackedMessage
function StackedMessage.new(id, time, route, sender, toSend)
    local instance = {}
    setmetatable(instance, StackedMessage)

    instance.id = id
    instance.time = 0
    instance.route = route
    instance.sender = sender
    instance.toSend = toSend

    return instance
end
function StackedMessage:send()
    --[[
            Compatibility issue: ComputerCraft 1.6

            On 1.6, rednet.send not only sends on the target channel, but on the broadcast channel
            They is undesirable, as it means messages will take all possible routes, not just the fastest

            To avoid this, the modem API is accessed directly
        ]]

    local modem = peripheral.wrap("back")
    modem.transmit(tonumber(self.route), tonumber(self.sender), self.toSend) -- this is for compatibility reasons
    self.time = os.time()
end
function StackedMessage:getID()
    return self.id
end



-- Table.class
--[[
	A networking table. Stores information about all nodes on network, and
	the shortest route to get there

	It works by accepting "information queries" from other nodes, and using it to construct a table
	on which nodes are available, how many "hops" away they are, and through which node to access them

	As every node is periodically broadcasting this information and calculating its own neighbours,
	 over time a best route is found to every node
]]

Table = {}
Table.__index = Table
function Table.new()
    local instance = {}
    setmetatable(instance, Table)

    instance.neighbours = {}

    return instance
end
function Table:addNeighbour(computer)
    local i
    for i = 1, table.getn(inst_Table.neighbours) do
        local neighbour = inst_Table.neighbours[i]

        -- try to find the computer in the list
        if (tonumber(neighbour:getID()) == tonumber(computer:getID())) then
            if (tonumber(neighbour:getDistance()) > tonumber(computer:getDistance())) then
                -- It's shorter distance!
                neighbour:setID(computer:getID())
                neighbour:setDistance(computer:getDistance())
                neighbour:setThroughID(computer:getThroughID())

                -- print ("Updated: " .. computer:getID() .. " + " .. computer:getDistance() .. " + " .. computer:getThroughID())
                return
            else
                -- it's longer distance, ignore it
                return
            end
        end

    end

    -- the computer was not in our table, so we need to add it
    table.insert(self.neighbours, computer)
    -- because we just added someone new to the network, we should update our friends
    if rednet.isOpen("back") then
        self:sendQuery()
    end
    -- print ("Added: " .. computer:getID() .. " + " .. computer:getDistance() .. " + " .. computer:getThroughID())
end
function Table:findRoute(targetID)
    local i
    local toUse = -1
    local distance = -1
    -- Find shortest distance
    for i = 1, table.getn(self.neighbours) do
        local computer = self.neighbours[i] -- this is an instance of computer
        if (tonumber(computer:getID()) == tonumber(targetID)) then
            if tonumber(computer:getDistance()) < tonumber(distance) or tonumber(distance) == -1 then
                -- Either shorter, or only one
                toUse = tonumber(computer:getThroughID())
                distance = tonumber(computer:getDistance())
            end
        end
    end

    if toUse == -1 then
        return nil
    end

    return toUse
end
function Table:readQuery(message)
    local payload = message:getPayload()
    local totalNeighbours = payload[1]

    -- First add the one that responded
    self:addNeighbour(Computer.new(message:getSender(), 1, message:getSender()))

    local i
    local pos = 2
    for i = 1, totalNeighbours do
        self:addNeighbour(Computer.new(payload[pos], payload[pos+1] + 1, message:getSender()))
        pos = pos + 2
    end
end
function Table:sendQuery()
    local inst_Message = Message.new()
    inst_Message:addPayload(table.getn(self.neighbours))
    for i=1, table.getn(self.neighbours) do
        local computer = self.neighbours[i]

        inst_Message:addPayload(computer:getID())
        inst_Message:addPayload(computer:getDistance())
    end

    inst_Message:setType("query")
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())

    inst_Message:broadcast()
end



-- Message.class
--[[
	A model of a message class. It allows you to easily create a packet, and
	then send it. Just provide it with:

	setTarget() -- the target computer. !!Not needed for broadcast!!
	setType() -- a string to define the messages purpose (e.g. an event has occured)
	setNetwork() -- a string stating which network to be sent on
	addPayload() -- call multiple times for each value to add to the packet
	setSender() -- set the id of the computer which sent the message

	And call either send or broadcast.
]]
Message = {}
Message.__index = Message
Message.sep = ";"
function Message.new()
    local instance = {}
    setmetatable(instance, Message)

    instance.payload = { }
    instance.id = nil
    instance.type = nil
    instance.network = nil
    instance.target = nil
    instance.sender = nil

    return instance
end
function Message:send()
    if self.type == nil or self.network == nil or self.target == nil or self.sender == nil then
        return false
    end

    local toSend = CURRENT_ID .. Message.sep .. self.network .. Message.sep .. self.target .. Message.sep .. self.sender .. Message.sep .. self.type .. Message.sep
    local i
    for i = 1, table.getn(self.payload) do
        toSend = toSend .. self.payload[i] .. Message.sep
    end

    local route = inst_Table:findRoute(self.target)

    if route ~= nil then
        --[[
            Compatibility issue: ComputerCraft 1.6

            On 1.6, rednet.send not only sends on the target channel, but on the broadcast channel
            They is undesirable, as it means messages will take all possible routes, not just the fastest

            To avoid this, the modem API is accessed directly
        ]]
        --local modem = peripheral.wrap("back")
        --modem.transmit(tonumber(route), tonumber(self.sender), toSend) -- this is for compatibility reasons

        table.insert(STACK, StackedMessage.new(CURRENT_ID, os.time(), route, self.sender, toSend))
        CURRENT_ID = CURRENT_ID + 1

        return true
    else
        return false
    end
end
function Message:sendUnreliable()
    if self.type == nil or self.network == nil or self.target == nil or self.sender == nil then
        return false
    end

    local toSend = self.id .. Message.sep .. self.network .. Message.sep .. self.target .. Message.sep .. self.sender .. Message.sep .. self.type .. Message.sep
    local i
    for i = 1, table.getn(self.payload) do
        toSend = toSend .. self.payload[i] .. Message.sep
    end

    local route = inst_Table:findRoute(self.target)

    if route ~= nil then
        --[[
            Compatibility issue: ComputerCraft 1.6

            On 1.6, rednet.send not only sends on the target channel, but on the broadcast channel
            They is undesirable, as it means messages will take all possible routes, not just the fastest

            To avoid this, the modem API is accessed directly
        ]]
        local modem = peripheral.wrap("back")
        modem.transmit(tonumber(route), tonumber(self.sender), toSend) -- this is for compatibility reasons

        return true
    else
        return false
    end
end
function Message:broadcast()
    if self.type == nil or self.network == nil or self.sender == nil then
        return false
    end

    local toSend = "0" .. Message.sep .. self.network .. Message.sep .. "broadcast" .. Message.sep .. self.sender .. Message.sep .. self.type .. Message.sep
    local i
    for i = 1, table.getn(self.payload) do
        toSend = toSend .. self.payload[i] .. Message.sep
    end

    rednet.broadcast(toSend)
    return true
end
function Message:broadcastAll()
    local node
    for node = 2, table.getn(inst_Table.neighbours) do
        local computer = inst_Table.neighbours[node]
        self:setTarget(computer:getID())
        if not self:send() then
            return false
        end
    end

    return true
end
function Message:getNetwork()
    return self.network
end
function Message:getType()
    return self.type
end
function Message:getTarget()
    return self.target
end
function Message:getPayload()
    return self.payload
end
function Message:getSender()
    return self.sender
end
function Message:setNetwork(network)
    self.network = network
end
function Message:setType(type)
    self.type = type
end
function Message:setTarget(target)
    self.target = target
end
function Message:setSender(sender)
    self.sender = sender
end
function Message:addPayload(value)
    table.insert(self.payload, value)
end
function Message:getID()
    return self.id
end
function Message:setID(id)
    self.id = id
end
function Message:parse(input)
    local array = {}
    array = api_os.splitString(input)

    self.id = array[1]
    self.network = array[2]
    self.target = array[3]
    self.sender = array[4]
    self.type = array[5]

    local i
    for i = 6, table.getn(array) do
        self:addPayload(array[i])
    end
end



-- Computer.class
--[[
	Represents a node on the network. It stores the computer's id,
	how many "hops" away it is, and through which node can it be reached
]]
Computer = {}
Computer.__index = Computer
function Computer.new(id, distance, throughID, name)
    local instance = {}
    setmetatable(instance, Computer)

    instance.id = id
    instance.distance = distance
    instance.throughID = throughID

    return instance
end
function Computer:getID()
    return self.id
end
function Computer:getDistance()
    return self.distance
end
function Computer:getThroughID()
    return self.throughID
end
function Computer:setID(id)
    self.id = id
end
function Computer:setDistance(distance)
    self.distance = distance
end
function Computer:setThroughID(throughID)
    self.throughID = throughID
end


-- Create a default networking table
inst_Table = Table.new()
-- Create this computer, because it knows enough about itself
inst_Computer = Computer.new(os.getComputerID(), 0, os.getComputerID())
-- Add itself to network
inst_Table:addNeighbour(inst_Computer)