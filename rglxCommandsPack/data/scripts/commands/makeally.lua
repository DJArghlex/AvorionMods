package.path = package.path .. ";data/scripts/lib/?.lua"

include ("relations")
commandName = "/makeAlly"
commandDescription = "Makes your target's faction an ally (and gives you one of their faction maps if they're an AI faction)"
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


	changeRelations(usingFaction, targetFaction, 200000)
	Galaxy():setFactionRelationStatus(usingFaction, targetFaction, RelationStatus.Allies, true, true)
	
	if targetFaction.isAIFaction and not targetFaction.isAlliance and not targetFaction.isPlayer and not targetFaction.alwaysAtWar then
		print("AI faction! granting a map.")

		local homeX, homeY = targetFaction:getHomeSectorCoordinates()
		local factionMapItem = UsableInventoryItem("factionmapsegment.lua", Rarity(RarityType.Legendary), targetFaction.index, homeX, homeY, homeX, homeY)

		player:getInventory():addOrDrop(factionMapItem)
	end

	returnValue = commandName .. ": Made " .. targetFaction.name .. " an ally of " .. usingFaction.name
	print( player.name .. returnValue )
	return 0, returnValue, returnValue
end