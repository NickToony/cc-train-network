dependencies = {}
table.insert(dependencies, {os_constants.os_url("holder/main.lua"), "main", false})

print("Preparing to update..")
math.randomseed(os.time())
os.sleep(math.random(5))
if api_os.update(dependencies) == true then
    print "Update Successful, Launching main .."
    os.sleep(3)
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