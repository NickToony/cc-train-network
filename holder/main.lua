SIDE_RELEASE_TRAIN = "left"
SIDE_TRAIN_PRESENT = "top"
SIDE_AVAILABLE = "right"

TIMER_RELEASE_TRAIN = 5

status = 0
hasCreated = false
controllerID = -1
lastBroadcast = 0
freedAt = 0

--[[ SETUP ]]
function setup()
    print("/-------------------/")
    print(" Holding Computer v2")
    print("---------------------")
    print("Detected type: " .. api_os.getType())
    print("Detected name: " .. api_os.getName())

    api_net.prepare()
end

function freeTrain()
    if status == os_constants.STATUS_HAS_TRAIN then
        redstone.setOutput(SIDE_RELEASE_TRAIN, true)
        freedAt = os.time()
    end
end

function handleMessage(message)
    -- This is the normal "tick" event, where it should handle things
    if message:getType() == os_constants.MESSAGE_RELEASE_TRAIN then
        freeTrain()
    end
end

function handleCreateMessage(message)
    -- This event occurs when the controller does not have us registered yet
    -- So we should send a message and tell it our state
    if message:getType() == "created" then
        hasCreated = true
        updateStatus()
        print "Created"
    end
end

function sendCreate()
    if controllerID == -1 then
        return
    end

    if math.abs(lastBroadcast - os.time()) < api_os.calcTime(10) then
        return
    end
    lastBroadcast = os.time()

    local inst_Message = api_net.Message.new()
    inst_Message:setType("create")
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())
    inst_Message:setTarget(controllerID)

    -- payload
    inst_Message:addPayload(api_os.getType())
    inst_Message:addPayload(api_os.getName())

    inst_Message:send()
end

function update()
    local hasTrain = redstone.getInput(SIDE_TRAIN_PRESENT)
    if hasTrain then
        setStatus(os_constants.STATUS_HAS_TRAIN)
    else
        setStatus(os_constants.STATUS_NO_TRAIN)
    end

    if (math.abs(freedAt - os.time()) > api_os.calcTime(TIMER_RELEASE_TRAIN)) then
        redstone.setOutput(SIDE_RELEASE_TRAIN, false)
        redstone.setOutput(SIDE_AVAILABLE, not hasTrain)
    end

end

function updateStatus()
    print("STATUS WAS CHANGED: " .. status)

    if controllerID == -1 then
        return
    end

    local inst_Message = api_net.Message.new()
    inst_Message:setType(os_constants.MESSAGE_STATUS)
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())
    inst_Message:setTarget(controllerID)

    -- payload
    inst_Message:addPayload(status)

    inst_Message:send()
end

function setStatus(stat)
    if stat ~= status then
        status = stat
        updateStatus()
    end
end

--[[ MAIN ]]
function main()
    setup()

    while true do
        local message = api_net.handleMessages()
        if message == nil then

        else
            if message:getType() == os_constants.MESSAGE_REBOOT then
                message:broadcastAll()
                api_net.handleStack()
                os.reboot()
            elseif message:getType() == os_constants.MESSAGE_HELLO then
                print("master said hello!")
            elseif message:getType() == os_constants.MESSAGE_CONTROL_ANNOUCE then
                if controllerID == -1 or controllerID ~= tonumber(message:getSender()) then
                    print("Detected controller: " .. message:getSender())
                    hasCreated = false
                end
                controllerID = tonumber(message:getSender())
            else
                if hasCreated then
                    handleMessage(message)
                else
                    handleCreateMessage(message)
                end
            end
        end

        update()

        if hasCreated == false then
            -- Re-send the create message
            sendCreate()
        end
    end
end

--[[ RUN ]]
local programSuccess, programVal = pcall(main)
if programSuccess then
    print("Program Success")
else
    print (programVal)
    if not shell.run("backup") then
        error()
    end
end