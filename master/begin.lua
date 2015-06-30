dependencies = {}
table.insert(dependencies, {os_constants.os_url("master/main.lua"), "main", false})
table.insert(dependencies, {os_constants.os_url("master/rebootall.lua"), "rebootall", false} )
table.insert(dependencies, {os_constants.os_url("master/helloall.lua"), "helloall", false} )

print("Preparing to update..")
math.randomseed(os.time())
os.sleep(math.random(5))
if api_os.update(dependencies) == true then
    print "Update Successful, Launching main .."
    os.sleep(1)
    shell.run("clear")
    if not shell.run("main") then
        if not shell.run("backup") then
            print()
            print()
            print("---------BLUE SCREEN---------")
            print("-----------------------------")
            print("System completely fucked up..")
            print(" will reboot in 120 seconds")
            print("-----------------------------")
            os.sleep(120)
            os.restart()
        end
    end
else
    print("Update failed. Retry in 10 seconds")
    os.sleep(10)
    os.reboot()
end