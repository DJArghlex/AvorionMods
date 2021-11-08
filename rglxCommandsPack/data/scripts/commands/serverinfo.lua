package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/serverinfo"
commandDescription = "Shows some more information about the server."
commandHelp = ""

local rulesFile = Server().folder .. "/serverinfo.txt"

function checkIfFileExists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end


function execute(sender, commandName, ...)
	local args = ...
	local player = Player()
	local returnValue = nil

	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end
	
	returnValue = "Server information:\n"

	if checkIfFileExists(rulesFile) then
		local FILE = assert(io.open(rulesFile, "r"))
		returnValue = returnValue .. FILE:read("*all")
		FILE:close()
		FILE = nil
	else
		-- file isn't present. return a default string of some kind.
		print(commandName .. ": Galaxy has no server information configured. Place some text in a file called serverinfo.txt in the root of your galaxy.")
		returnValue = "This galaxy has no server information configured. Ask your administrators."
	end

	print( player.name .. " requested galaxy's server information." )
	return 0, returnValue, returnValue
end