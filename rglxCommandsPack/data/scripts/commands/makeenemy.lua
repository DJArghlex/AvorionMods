package.path = package.path .. ";data/scripts/lib/?.lua"

include ("relations")

commandName = "/makeEnemy"
commandDescription = "Makes your target's faction an enemy."
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
		returnValue = commandName .. ": Drones don't need crew. Did you forget to select a target?"
		return 1, returnValue, returnValue
	end

	local targetCraft = self.selectedObject
	if not targetCraft then
		returnValue = commandName .. ": No target selected."
		return 1, returnValue, returnValue
	end

	usingFaction = Faction(self.factionIndex)
	if not usingFaction then
		returnValue = commandName .. ": Your craft isn't owned by any faction."
		return 1, returnValue, returnValue
	end

	targetFaction = Faction(targetCraft.factionIndex)
	if not targetFaction then
		returnValue = commandName .. ": Target craft isn't owned by any faction."
		return 1, returnValue, returnValue
	end
	
	if usingFaction.index == targetFaction.index then
		returnValue = commandName .. ": This is one of your ships."
		return 1, returnValue, returnValue
	end


	changeRelations(usingFaction, targetFaction, -200000)
	Galaxy():setFactionRelationStatus(usingFaction, targetFaction, RelationStatus.War, true, true)
	
	returnValue = commandName .. ": Made " .. targetFaction.name .. " an enemy of " .. usingFaction.name
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end