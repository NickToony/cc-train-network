print("An error occured that the program could not recover from.")
print("Awaiting master reboot..")
rednet.open("back")
while true do
    local message = api_net.handleMessages()
    if message == nil then

    else
        if message:getType() == "reboot" then
            message:broadcastAll()
            os.reboot()
        end
    end
end