package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/delete"
commandDescription = "Deletes an entity using a specified method of destruction."
commandHelp = "[jump/explode/vanish]"

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
	
	if not player then
		returnValue = commandName .. ": Player isn't present?"
		return 1, returnValue, returnValue
	end

	local self = player.craft
	if not self then
		returnValue = commandName .. ": You're not in a craft of any kind."
		return 1, returnValue, returnValue
	end

	local craft = self.selectedObject

	if not craft then
		returnValue = commandName .. ": Ship is not targetting an entity."
		return 1, returnValue, returnValue
	end

	local craftName = craft.name
	if craftName == nil then
		craftName = ""
	end
	local craftTitle = craft.title
	if craftTitle == nil then
		craftTitle = ""
	end

	if args == "jump" then
		Sector():deleteEntityJumped(craft)
		returnValue = commandName .. ": Deleted entity " .. craftTitle .. " " .. craftName .. " (by hyperspacing it)"
	elseif args == "explode" then
		if craft.isStation or craft.isShip then
			craft:destroy(craft.id)
			returnValue = commandName .. ": Deleted entity " .. craftTitle .. " " .. craftName .. " (by exploding it)"
		else
			returnValue = commandName .. ": You can only explode ships and stations!"
			return 1, returnValue, returnValue
		end
	elseif args == "vanish" then
		Sector():deleteEntity(craft)
		returnValue = commandName .. ": Deleted entity " .. craftTitle .. " " .. craftName .. " (by vanishing it)"
	else
		returnValue = commandName .. ": Specify a method of removal! [explode/vanish/jump]"
		return 1, returnValue, returnValue
	end

	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end