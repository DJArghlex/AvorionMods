package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/repair"
commandDescription = "Repairs your ship (or its target) and its shields. (cannot replace missing blocks!)"
commandHelp = ""

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end


function execute(sender, commandName, ...)
	local args = {...}
	
	local player = Player()
	if not player then
		return 1, "", commandName .. ": Player isn't present?"
	end

	local self = player.craft
	if not self then
		return 1, "", commandName .. ": Drones don't need crew."
	end

	local craft = self.selectedObject or self

	craft.durability = craft.maxDurability
	craft.shieldDurability = craft.shieldMaxDurability

	returnValue = commandName .. ": Repaired " .. craft.title .. " " .. craft.name
	print( player.name .. returnValue )
	return 0, returnValue, returnValue
end