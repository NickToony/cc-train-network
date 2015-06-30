myName = nil
myType = nil

local yieldTime=os.clock()
function yield()
    if math.abs(os.clock()-yieldTime)>2 then
        os.queueEvent("yield")
        os.pullEvent()
        yieldTime=os.clock()
    end
end

-- install
--[[
	This is the full implementation of install.
	It will fetch a script from the provider url, and save it as a file (removing the old one)
	If API is set to true, it will load the script as a system API
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

-- update
--[[
	Given an array of dependencies, it will install each and report any errors
	See install() for more information of parameters

	format:

	{
		{url, file, api?},
		{url, file, api}
	}
]]
function update(dependencies)

    for i=1, table.getn(dependencies) do
        local dependency = dependencies[i]
        local success = install(dependency[1], dependency[2], dependency[3])
        if not success then
            return false
        end
    end

    return true

end

-- Get the system type
function getType()
    if myType == nil then
        local filePath   = "myType"

        -- check it exists
        if not fs.exists(filePath) then
            local fileHandle = fs.open(filePath, 'w')
            print ("Type is not defined. Set: ")
            fileHandle.write(read())
            fileHandle.close()
        end

        local fileHandle = fs.open (filePath, 'r')
        myType = fileHandle.readAll()
        fileHandle.close()
    end

    return myType
end

-- Get the system name
function getName()
    if myName == nil then
        local filePath   = "myName"

        -- check it exists
        if not fs.exists(filePath) then
            local fileHandle = fs.open(filePath, 'w')
            print ("Name is not defined. Set: ")
            fileHandle.write(read())
            fileHandle.close()
        end

        local fileHandle = fs.open (filePath, 'r')
        myName = fileHandle.readAll()
        fileHandle.close()
    end

    return myName
end

function splitString(inputstr)
    local sep = ";"
    local t={} ; i=1

    for str in string.gmatch(inputstr, "([^".. sep .."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function calcTime(seconds)
    return (0.02 * seconds)
end

function shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function findInTable(t, val)
    local i
    for i = 1, table.getn(t) do
        if t[i] == val then
            return t
        end
    end
    return nil
end