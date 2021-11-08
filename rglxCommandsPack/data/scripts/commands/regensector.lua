package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/regenSector"
commandDescription = "Regenerates this sector, without touching player/alliance ships."
commandHelp = ""

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

	
	returnValue = commandName .. ": not yet implemented."
	print( player.name .. " ran " .. returnValue )
	return 1, returnValue, returnValue
end