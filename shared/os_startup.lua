-- install
--[[ 
	a basic script for getting the auto-updater going (as the dependencies may not be available)
	It will install the code from the url as a file. See api_net for the full implementation
]]
function install(url, file, api)
    print ("Acquiring file.. " .. file)
    local data = http.get(url)

    if data == nil then
        return false
    end

    if not data.getResponseCode() == 200 then
        return false
    end

    fs.delete(file)

    local h = fs.open(file, "w")
    h.write(data.readAll())
    h.close()

    if api then
        print ("Loading API.. " .. file)
        if not os.loadAPI(file) then
            return false
        end
    end

    return true
end

-- Install the api_os, which provides the full implementation of install
install("https://dl.dropboxusercontent.com/u/30677896/ComputerCraft/Trains2/shared/api_os.lua", "api_os", true)
install("https://dl.dropboxusercontent.com/u/30677896/ComputerCraft/Trains2/shared/os_constants.lua", "os_constants", true)

-- Define some dependancies depending on the system type
dependencies = {}
if api_os.getType() == "c" then -- controller
table.insert(dependencies, {os_constants.os_url("controller/begin.lua"), "begin", false})
elseif api_os.getType() == "s" then -- station
table.insert(dependencies, {os_constants.os_url("station/begin.lua"), "begin", false})
elseif api_os.getType() == "m" then -- master
table.insert(dependencies, {os_constants.os_url("master/begin.lua"), "begin", false})
elseif api_os.getType() == "h" then -- holder
table.insert(dependencies, {os_constants.os_url("holder/begin.lua"), "begin", false})
end

-- All systems need the backup dependency, in case of errors, it's nice to be able to recover
table.insert(dependencies, {os_constants.os_url("shared/os_backup.lua"), "backup", false})
-- Shared dependencies
table.insert(dependencies, {os_constants.os_url("shared/api_net.lua"), "api_net", true})


-- Output nice text
shell.run("clear")
print("----> TrainOS v2")
print()
print("Preparing to startup ..")
print("Detected type: " .. api_os.getType())
print("Detected name: " .. api_os.getName())
print()
print("Fetching core dependencies ..")
-- randomise the pause, so all HTTP requests are not simultaneous across systems
math.randomseed(os.time())
os.sleep(math.random(5))
-- If dependencies successfully acquired
if api_os.update(dependencies) == true then
    print "Startup Successful. Launching begin .."
    print ()
    os.sleep(1)
    shell.run("begin") -- start the main program
else
    print()
    print("Startup failed. Retry in 10 seconds")
    os.sleep(10)
    os.reboot()
end