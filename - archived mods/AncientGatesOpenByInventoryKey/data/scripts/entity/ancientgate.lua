function AncientGate.update(timeStep)
	enabledTime = enabledTime - timeStep 


	local first = Sector():getEntitiesByScript("data/scripts/systems/teleporterkey1.lua")

	if first then
		print ("ancient gate: opened by way of key installation on a ship.")
		enabledTime = 60 -- having the key in-sector on a ship opens the gate for fifteen minutes
	else
		-- once every 60 seconds
		print("ancient gate: checking sector!")

		local presentFactions = AncientGate.listAllNonNpcFactionsInSector()

		for factionId in presentFactions do
			faction = Faction(factionId)
			print(factionId, faction.name)
		end
	end

	WormHole().enabled = enabledTime > 0
end

function AncientGate.checkPlayerInventoryForKey(playerId)
	-- pretty much just copied from data/scripts/entity/story/exodustalkbeacon.lua
	local player = Player(playerId)
	print (player.name)

	-- check inventory
	local upgrades = player:getInventory():getItemsByType(InventoryItemType.SystemUpgrade)

	for _, item in pairs(upgrades) do
		if item.item.script:find("teleporterkey1") then
			return true
		end
	end
	return false

end

function AncientGate.listAllNonNpcFactionsInSector()

	local sector = Sector()
	local allShips = sector:getEntitiesByType(EntityType.Ship)
	local allStations = sector:getEntitiesByType(EntityType.Station)

	local output = {}

	for entity in allShips do
		local owningFaction = Faction(entity.factionIndex)
		if owningFaction ~= nil then
			if owningFaction.isAlliance then
				output[owningFaction.index] = true
			elseif owningFaction.isPlayer then
				output[owningFaction.index] = true
			end
		end
	end
	for entity in allStations do
		local owningFaction = Faction(entity.factionIndex)
		if owningFaction ~= nil then
			if owningFaction.isAlliance then
				output[owningFaction.index] = true
			elseif owningFaction.isPlayer then
				output[owningFaction.index] = true
			end
		end
	end
	return output
end

function AncientGate.getUpdateInterval()
    return 5
end