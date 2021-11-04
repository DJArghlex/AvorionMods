package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/rules"
commandDescription = "Shows the galaxy's rules."
commandHelp = ""

local rulesFile = Server().folder .. "/rules.txt"

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

	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end
	
	local returnValue = "Galactic rules are as follows:\n"

	if checkIfFileExists(rulesFile) then
		local FILE = assert(io.open(rulesFile, "r"))
		returnValue = returnValue .. FILE:read("*all")
		FILE:close()
		FILE = nil
	else
		-- file isn't present. return a default string of some kind.
		print(commandName .. ": Galaxy has no rules configured. Place some text in a file called rules.txt in the root of your galaxy.")
		returnValue = "This galaxy has no rules configured. Ask your administrators."
	end

	print( player.name .. " requested galaxy's rules." )
	return 0, returnValue, returnValue
end