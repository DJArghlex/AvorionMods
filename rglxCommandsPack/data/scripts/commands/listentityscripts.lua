local commandName = "/listEntityScripts"
local commandDescription = "Lists entity scripts on currently targetted (or piloted, if none) entity."
local commandHelp = ""

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

function execute(sender, commandName, ...)
	local args = {...}
	--print(args[1])
	local playerId = tonumber(args[1])
	local returnValue = nil

	local player = Player()
	local server = Server()
	local galaxy = Galaxy()


	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		returnValue = commandName .. ": This cannot be run from console."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	elseif not server:hasAdminPrivileges(player) then
		returnValue = commandName .. ": You don't have permission."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	if not player.craft then
		returnValue = commandName .. ": Enter a ship or drone."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local target = nil
	if not player.craft.selectedObject then
		target = player.craft -- ship is targetting nothing
	returnValue = "Entity scripts loaded on your piloted ship:\n"
	else
		target = player.craft.selectedObject
	returnValue = "Entity scripts loaded on your targetted ship:\n"
	end


	for scriptId, scriptName in pairs(target:getScripts()) do
		returnValue = returnValue .. tostring(scriptId) .. "|" .. tostring(scriptName)
	end

	-- and return to the executing player.
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue

end