MESAGE_HANDLED = 0;
MESSAGE_CREATED = 1;
MESSAGE_UNHANDLED = 2;

controllerId = -1
hasCreated = false
lastBroadcast = 0;

function sendCreate()
    if controllerId == -1 then
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
    inst_Message:setTarget(controllerId)

    -- payload
    inst_Message:addPayload(api_os.getType())
    inst_Message:addPayload(api_os.getName())

    inst_Message:send()
end

function handleCreateMessage(message)
    -- This event occurs when the controller does not have us registered yet
    -- So we should send a message and tell it our state
    if message:getType() == "created" then
        hasCreated = true
        print "Created"
    end
end

function handleMessage(message)
    if message:getType() == os_constants.MESSAGE_REBOOT then
        message:broadcastAll()
        api_net.handleStack()
        os.reboot()
    elseif message:getType() == os_constants.MESSAGE_HELLO then
        print("master said hello!")
    elseif message:getType() == os_constants.MESSAGE_CONTROL_ANNOUCE then
        if controllerId == -1 or controllerId ~= tonumber(message:getSender()) then
            print("Detected controller: " .. message:getSender())
            hasCreated = false
        end
        controllerId = tonumber(message:getSender())
    else
        if hasCreated then
            return MESSAGE_UNHANDLED;
        else
            handleCreateMessage(message);
            if hasCreated then
                return MESSAGE_CREATED;
            else
                return MESAGE_HANDLED;
            end
        end
    end
end

function step()
    if not hasCreated then
        sendCreate()
    end
end