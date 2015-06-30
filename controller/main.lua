--[[
	TODO:
		- Make stations follow NETWORK rules (e.g. output redstone on correct side) --- DONE
		- Make idle trains return to base --- DONE
]]

LAST_BROADCAST = 0

fieldHolders = { }
fieldNodes = { }
fieldTrains = { }
fieldStations = { }

LOCATION_STORAGE = -1
LOCATION_STORAGE_NAME = "STORAGE"


--[[
	 _______  _______  _        _______ _________ _______ 
	(  ____ \(  ___  )( (    /|(  ____ \\__   __/(  ____ \
	| (    \/| (   ) ||  \  ( || (    \/   ) (   | (    \/
	| |      | |   | ||   \ | || (__       | |   | |      
	| |      | |   | || (\ \) ||  __)      | |   | | ____ 
	| |      | |   | || | \   || (         | |   | | \_  )
	| (____/\| (___) || )  \  || )      ___) (___| (___) |
	(_______/(_______)|/    )_)|/       \_______/(_______)

	The network configuration. e.g. which station goes to what?
]]

NETWORK =
{
    {	"STORAGE", -1,				{	"none", "holder_control"	}	}, -- from storage, you can get to holder control
    {	"holder_control", nil	,		{ 	"left", "holder_enter"	}, 	{	"none",	"sandpool_out"	}		}, -- the holder_control station knows how to get to STORAGE left,
    {	"holder_enter", nil, 		{   "none", "STORAGE"	}	},
    {	"sandpool_out", nil, 	{	"none",	"corrupted_out"	}, 	{	"left",	"crossection_out"	}		},
    {	"corrupted_out", nil, 	{	"none",	"crossection_out"	}		},
    {	"crossection_out", nil, 	{	"none",	"end_out"	}	},
    {	"end_out", nil, 	{	"none",	"end_in"	}	},
    {	"end_in", nil, 	{	"none",	"crossection_in"	}	},
    {	"crossection_in", nil, 	{	"none",	"corrupted_in"	}, 	{	"left",	"sandpool_in"	}		},
    {	"corrupted_in", nil, 	{	"none",	"sandpool_in"	}	},
    {	"sandpool_in", nil, 	{	"none",	"holder_enter"	}	}
}
STORAGE_RESET_FINAL = LOCATION_STORAGE_NAME
STORAGE_RESET_CURRENT = "holder_control"
TOTAL_TRAINS = 4



--[[
		 _______  _______  _       _________ _______  _______  _        _        _______  _______ 
		(  ____ \(  ___  )( (    /|\__   __/(  ____ )(  ___  )( \      ( \      (  ____ \(  ____ )
		| (    \/| (   ) ||  \  ( |   ) (   | (    )|| (   ) || (      | (      | (    \/| (    )|
		| |      | |   | ||   \ | |   | |   | (____)|| |   | || |      | |      | (__    | (____)|
		| |      | |   | || (\ \) |   | |   |     __)| |   | || |      | |      |  __)   |     __)
		| |      | |   | || | \   |   | |   | (\ (   | |   | || |      | |      | (      | (\ (   
		| (____/\| (___) || )  \  |   | |   | ) \ \__| (___) || (____/\| (____/\| (____/\| ) \ \__
		(_______/(_______)|/    )_)   )_(   |/   \__/(_______)(_______/(_______/(_______/|/   \__/
                  

	A static class. It's just a way of grouping all the methods

	This will essetially be the class than runs/controls all others
]]
Controller = {}
function Controller.setup()
    print("/-------------------/")
    print(" Controller Computer")
    print("---------------------")
    print("Detected type: " .. api_os.getType())
    print("Detected name: " .. api_os.getName())

    api_net.prepare()
end
function Controller.handleMessage(message)
    if message:getType() == "create" then
        Controller.handleCreate(message)
    else
        -- find the node
        local i
        for i = 1, table.getn(fieldNodes) do
            local node = fieldNodes[i]
            if node[1] == message:getSender() then
                node[2]:handleMessage(message)
            end
        end
    end
end
function Controller.handleCreate(message)
    local payload = message:getPayload()

    print ("New node: " .. payload[1] .. " (" .. payload[2] .. ")" )

    -- if it's a holder
    if payload[1] == "h" then
        local holder = Station.new(message:getSender())
        table.insert(fieldHolders, holder)
        table.insert(fieldNodes, { holder:getID(), holder, holder:getName() })
    elseif payload[1] == "s" then
        local station = Station.new(message:getSender(), payload[2])
        table.insert(fieldStations, { station, station:getName() } )
        table.insert(fieldNodes, { station:getID(), station, station:getName() })
    end

    local inst_Message = api_net.Message.new()
    inst_Message:setType("created")
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())
    inst_Message:setTarget(message:getSender())

    inst_Message:send()
end
function Controller.sendPulse()
    if math.abs(LAST_BROADCAST - os.time()) < api_os.calcTime(10) then
        return
    end
    LAST_BROADCAST = os.time()

    local inst_Message = api_net.Message.new()
    inst_Message:setType("control_pulse")
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())

    inst_Message:broadcastAll()
end
function Controller.update()
    Controller.sendPulse()
    local i
    for i = 1, table.getn(fieldHolders) do
        local holder = fieldHolders[i]
        holder:update()
    end
    for i = 1, table.getn(fieldStations) do
        local station = fieldStations[i]
        local s = station[1]
        s:update()
    end
end
function Controller.main()
    Controller.setup()

    while true do
        local message = api_net.handleMessages()
        if message == nil then

        else
            if message:getType() == "reboot" then
                message:broadcastAll()
                api_net.handleStack()
                os.reboot()
            elseif message:getType() == "hello" then
                print("master said hello!")
            else
                Controller.handleMessage(message)
            end
        end

        Controller.update()

        api_os.yield()
    end
end
function Controller.findTrainByBlock(blockID)
    local i
    for i = 1, table.getn(fieldTrains) do
        local train = fieldTrains[i]
        if tonumber(train:getCurrentTarget()) == tonumber(blockID) or tonumber(train:getCurrentLocation()) == tonumber(blockID) then
            return train
        end
    end

    return nil
end
function Controller.findNextTarget(finalTarget, currentLocationName, lastLoc)
    local solution = nil
    local solutionDistance = nil
    local solutionDir = ""

    if currentLocationName == finalTarget then
        -- print ("It's the final target")
        solution = currentLocationName
        solutionDistance = 0
        solutionDir = ""
    end

    local myTable
    if (lastLoc ~= nil) then
        myTable = api_os.shallow_copy(lastLoc)
    else
        myTable = {}
    end
    table.insert(myTable, currentLocationName)

    local stationCount
    -- For each station in network
    for stationCount = 1, table.getn(NETWORK) do
        local station = NETWORK[stationCount]

        -- print("Checking station.. " .. station[1])

        -- if the station is our current location
        if station[1] == currentLocationName then
            -- print ("It's not the final target ,but our current location")
            local destinationCount
            -- for each of current locations destinations
            for destinationCount = 3, table.getn(station) do
                local intStation = station[destinationCount]
                if api_os.findInTable(myTable, intStation[2]) == nil then
                    -- print ("Recursively going to.. " .. finalTarget .. " from " .. intStation[2])
                    local result, distance, dir = Controller.findNextTarget(finalTarget, intStation[2], myTable)
                    -- if it has a route to the next station
                    if result ~= nil then
                        -- if it's closer
                        if solutionDistance == nil or distance < solutionDistance then
                            solution = intStation[2]
                            solutionDir = intStation[1]
                            solutionDistance = distance
                        end
                    end
                end
            end
        end
        -- print ("Looped")
    end

    if solutionDistance ~= nil then
        solutionDistance = solutionDistance + 1
    end
    return solution, solutionDistance, solutionDir
end
function Controller.stationNameToID(name)
    if (name == LOCATION_STORAGE_NAME) then
        return LOCATION_STORAGE
    end

    local i
    for i = 1, table.getn(fieldStations) do
        local station = fieldStations[i]
        if station[2] == name then
            local s = station[1]
            return s:getID()
        end
    end

    return nil
end
function Controller.randomStation()
    local num = math.random(table.getn(fieldStations))
    local station = fieldStations[num]
    return station[2]
end


--[[
	 _______ _________ _______ __________________ _______  _       
	(  ____ \\__   __/(  ___  )\__   __/\__   __/(  ___  )( (    /|
	| (    \/   ) (   | (   ) |   ) (      ) (   | (   ) ||  \  ( |
	| (_____    | |   | (___) |   | |      | |   | |   | ||   \ | |
	(_____  )   | |   |  ___  |   | |      | |   | |   | || (\ \) |
	      ) |   | |   | (   ) |   | |      | |   | |   | || | \   |
	/\____) |   | |   | )   ( |   | |   ___) (___| (___) || )  \  |
	\_______)   )_(   |/     \|   )_(   \_______/(_______)|/    )_)
                                                              
                                                      

	A model to represent a "station"

]]

Station = {}
Station.__index = Station
function Station.new(id, name)
    local instance = {}
    setmetatable(instance, Station)

    instance.status = 0
    instance.id = id
    instance.holdTime = 0
    instance.name = name

    return instance
end
function Station:getID()
    return self.id
end
function Station:getStatus()
    return self.status
end
function Station:setStatus(status)
    self.status = status
end
function Station:getName()
    return self.name
end
function Station:update()
    if self.status == "1" then
        if (math.abs(os.time() - self.holdTime) > api_os.calcTime(2 + math.random(4))) then
            -- find train
            local train = Controller.findTrainByBlock(self.id)
            if (train ~= nil) then
                -- check where to go next
                local finalDestination = train:getFinalTarget()
                if (Controller.stationNameToID(finalDestination) == train:getCurrentLocation()) or (finalDestination == train:getCurrentLocation()) then
                    -- if it's at its target, just go home (temporary)
                    finalDestination = STORAGE_RESET_FINAL
                    train:setFinalTarget(finalDestination)
                end
                local toStation, toDistance, toDir = Controller.findNextTarget(finalDestination, self.name, nil)
                if toStation ~= nil then
                    -- Is it free?
                    local toStationID = Controller.stationNameToID(toStation)
                    if (Controller.findTrainByBlock(toStationID) == nil) then
                        -- Set it to the new target
                        train:setNextTarget(toStationID)
                        train:setCurrentTarget(toStationID)
                        print ("Set next target: " .. toStationID)

                        self:freeTrain(toDir)
                        self.holdTime = os.time()
                    else
                        if math.random(1000) == 50 then
                            print ("Busy at " .. toStation .. " with id " .. toStationID)
                            print ("CT: " .. train:getCurrentTarget())
                            print ("CL: " .. train:getCurrentLocation())
                            local busyTrain = Controller.findTrainByBlock(toStationID)
                            print ("CT: " .. busyTrain:getCurrentTarget())
                            print ("CL: " .. busyTrain:getCurrentLocation())
                            print ("Trains: " .. table.getn(fieldTrains))
                        end
                    end
                else
                    print ("BAD THINGS HAPPENED, NO ROUTE FROM: " .. train:getCurrentLocation() .. " to " .. finalDestination)
                end
            else
                print "COULDNT FIND TRAIN"
            end
        else

        end
    else
        self.holdTime = os.time()
    end
end
function Station:freeTrain(direction)
    local inst_Message = api_net.Message.new()
    inst_Message:setType("free_train")
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())
    inst_Message:setTarget(self.id)

    inst_Message:addPayload(direction)

    inst_Message:send()
end
function Station:handleMessage(message)
    local payload = message:getPayload()
    if (message:getType() == "status") then
        self:setStatus(payload[1])
        -- if it was a train
        if self:getStatus() == "1" then
            -- Try to find the train that was heading there
            local train = Controller.findTrainByBlock(self.id)
            if (train == nil) then
                -- Train unknown .. add it!
                table.insert(fieldTrains, Train.new(message:getSender())) -- it's currently at the holding bay
                print ("NEW TRAIN!! " .. table.getn(fieldTrains))
            else
                -- It's a train we know about, let's find out where it wants to go
                print ("TRAIN ENTERED STATION " .. self.name)
                train:setCurrentLocation(self.id)
                train:setCurrentTarget(self.id)
            end
        else
            local train = Controller.findTrainByBlock(self.id)
            if (train ~= nil) then
                -- Train unknown .. add it!
                print ("TRAIN LEFT " .. self.name)
                train:setCurrentTarget(train:getNextTarget())
                print ("CT: " .. train:getCurrentTarget())
                print ("CL: " .. train:getCurrentLocation())
            end
        end
    end
end



--[[
	_________ _______  _______ _________ _       
	\__   __/(  ____ )(  ___  )\__   __/( (    /|
	   ) (   | (    )|| (   ) |   ) (   |  \  ( |
	   | |   | (____)|| (___) |   | |   |   \ | |
	   | |   |     __)|  ___  |   | |   | (\ \) |
	   | |   | (\ (   | (   ) |   | |   | | \   |
	   | |   | ) \ \__| )   ( |___) (___| )  \  |
	   )_(   |/   \__/|/     \|\_______/|/    )_)
  

	A model to represent a train.                         
]]
Train = {}
Train.__index = Train
function Train.new(currentComputer)
    local instance = { }
    setmetatable(instance, Train)

    instance.currentTarget = currentComputer
    instance.currentLocation = currentComputer
    instance.finalTarget = currentComputer
    instance.nextTarget = currentComputer

    return instance
end
function Train:getCurrentTarget()
    return self.currentTarget
end
function Train:getCurrentLocation()
    return self.currentLocation
end
function Train:getFinalTarget()
    return self.finalTarget
end
function Train:setCurrentTarget(target)
    self.currentTarget = target
end
function Train:setCurrentLocation(location)
    self.currentLocation = location
end
function Train:setFinalTarget(target)
    self.finalTarget = target
end
function Train:setNextTarget(target)
    self.nextTarget = target
end
function Train:getNextTarget()
    return self.nextTarget
end



--[[ RUN ]]
local programSuccess, programVal = pcall(Controller.main)
if programSuccess then
    print("Program Success")
else
    print (programVal)
    if not shell.run("backup") then
        error()
    end
end