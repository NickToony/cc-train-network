--[[ SETUP ]]
function setup()
    print("/-------------------/")
    print("   Master Computer v2")
    print("---------------------")
    print("Detected type: " .. api_os.getType())
    print("Detected name: " .. api_os.getName())

    api_net.prepare()
end
--[[ MAIN ]]
function main()
    setup()

    while true do
        local message = api_net.handleMessages()
    end
end

while true do
    local programSuccess, programVal = pcall(main)
    print(programVal)
    print()
    print("Paused... enter your command:")
    local command = read()
    if command == "reboot" then
        print "Rebooting all systems .. "
        shell.run("rebootall")
    elseif command == "hello" then
        print "Saying hello to all systems .. "
        shell.run("helloall")
    else
        print "Command not recognised"
    end
    print()
end