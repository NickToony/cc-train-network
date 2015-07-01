SIDE_RELEASE_TRAIN = "left"
SIDE_TRAIN_PRESENT = "top"
SIDE_AVAILABLE = "right"

TIMER_RELEASE_TRAIN = 5

status = 0
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

    if api_slave.hasCreated == false then
        return
    end

    local inst_Message = api_net.Message.new()
    inst_Message:setType(os_constants.MESSAGE_STATUS)
    inst_Message:setNetwork("default")
    inst_Message:setSender(os.getComputerID())
    inst_Message:setTarget(api_slave.controllerId)

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
            handled = api_slave.handleMessage(message)
            if handled == api_slave.MESSAGE_CREATED then
                updateStatus()
            elseif handled == api_slave.MESSAGE_UNHANDLED then
                handleMessage(message)
            end
        end

        update()

        api_slave.step()
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