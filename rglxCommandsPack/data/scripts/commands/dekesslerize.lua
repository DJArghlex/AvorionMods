package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/dekesslerize"
commandDescription = "Cleanses a sector of garbage."
commandHelp = ""

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end



local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

local function formatFactionName(factionName)
	stringToRemove = "/*This refers to factions, such as 'The Xsotan'.*/"
	if ends_with(factionName, stringToRemove) then
		return string.sub(factionName,1,( -1 - string.len(stringToRemove)))
	else
		return factionName
	end
end

function execute(sender, commandName, ...)
	local args = {...}
	local returnValue = nil

	local player = Player()
	local server = Server()
	local sector = Sector()
	local sectorX, sectorY = sector:getCoordinates()

	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		returnValue = commandName .. ": You can't run this from console."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	elseif not server:hasAdminPrivileges(player) then
		returnValue = commandName .. ": You don't have permission."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local removedEntityCount = {
		items=0,
		wrecks=0,
		fighters=0,
		torpedoes=0,
		beacons=0,
		pirates=0,
		xsotan=0,
		cargoships=0,
	}

	-- erase loot separately. sometimes this can be thousands of items, and we don't want to have the server thread hang for very long or the whole thing gets really cranky.
	for _, loot in pairs({sector:getEntitiesByType(EntityType.Loot)}) do
		sector:deleteEntity(loot)
		removedEntityCount.items = removedEntityCount.items + 1
	end

	for i, entity in pairs({sector:getEntities()}) do
		if entity == nil then
			-- deleted or otherwise invalid entity
			goto continue
		end

		if entity.type == nil then
			-- deleted or otherwise invalid entity type
			goto continue
		end

		if entity.type == EntityType.Loot then
			-- loot items. these should already be deleted above so as to not slow this loop way down, but can't hurt to be sure.
			sector:deleteEntity(entity)
			removedEntityCount.items = removedEntityCount.items + 1
		end

		if entity.type == EntityType.Wreckage then
			-- wreckages. deleting them all will remove abandoned ships/stations, and will empty scrapyards, but that is considered acceptable for the purposes of this script. maybe someday i'll write specific exceptions for the sector.
			sector:deleteEntity(entity)
			removedEntityCount.wrecks = removedEntityCount.wrecks + 1
		end

		if entity.type == EntityType.Fighter then
			-- fighters. pretty straightforward. deletes player and alliance AND NPC fighters. be careful.
			sector:deleteEntity(entity)
			removedEntityCount.fighters = removedEntityCount.fighters + 1
		end

		if entity.type == EntityType.Torpedo then
			-- torpedoes. not much of a loss here anyway.
			sector:deleteEntity(entity)
			removedEntityCount.torpedoes = removedEntityCount.torpedoes + 1
		end

		-- energy signature suppressors, sector labellers, marker buoys, and radio chatter beacons
		-- data/scripts/entity/energysuppressor.lua
		-- data/scripts/entity/sectorrenamingbeacon.lua
		-- data/scripts/entity/markerbuoy.lua
		-- data/scripts/entity/messagebeacon.lua


		if entity.type == EntityType.None then
			if entity:hasScript("data/scripts/entity/energysuppressor.lua") then
				sector:deleteEntity(entity)
				removedEntityCount.beacons = removedEntityCount.beacons + 1
			end
			if entity:hasScript("data/scripts/entity/sectorrenamingbeacon.lua") then
				sector:deleteEntity(entity)
				removedEntityCount.beacons = removedEntityCount.beacons + 1
			end
			if entity:hasScript("data/scripts/entity/markerbuoy.lua") then
				sector:deleteEntity(entity)
				removedEntityCount.beacons = removedEntityCount.beacons + 1
			end
			if entity:hasScript("data/scripts/entity/messagebeacon.lua") then
				sector:deleteEntity(entity)
				removedEntityCount.beacons = removedEntityCount.beacons + 1
			end
		end



		if entity.type == EntityType.Ship then
			-- all ships

			if entity.playerOrAllianceOwned == true then
				-- exclude player or alliance owned ships
				goto continue2
			end

			local owningFaction = Faction(entity.factionIndex)
			if owningFaction == nil then
				-- exclude crafts without owning factions
				goto continue2
			else

				if ends_with(formatFactionName(owningFaction.name)," Pirates") then
					-- remove all pirate ships
					sector:deleteEntity(entity)
					removedEntityCount.pirates = removedEntityCount.pirates + 1
				end

				if formatFactionName(owningFaction.name) == "The Xsotan" then
					-- remove all xsotan ships
					sector:deleteEntity(entity)
					removedEntityCount.xsotan = removedEntityCount.xsotan + 1
				end

				-- NPC ships with data/scripts/entity/ai/passsector.lua loaded are the ships that enter sectors, loiter for a bit, then leave. prison transports, party buses, traders and the like have it loaded for the most part.
				-- NPC ships with data/scripts/entity/merchants/tradeship.lua are the ships that enter sectors, fly to a station, trade, then leave. these can be somewhat extreme in their server load if you have a sector with a bunch of stations far off from the sector's center.
				-- both of these ships have data/scripts/entity/civilship.lua loaded (the piracy/story chatter interact menu) which makes this a better way to determine and remove NPC ships that are actually causing problems.
				-- we do NOT want to remove the defender ships that spawn in a sector, as this invariably gets the stations there killed (or damaged heavily) before more NPC reinforcements arrive.

				if entity:hasScript("data/scripts/entity/civilship.lua") then
					-- hasScript() returns the total number of instances of that script that's loaded into the entity
					sector:deleteEntity(entity)
					removedEntityCount.cargoships = removedEntityCount.cargoships + 1
				end

				-- and that's all the things we need to delete.

			end

			-- bail-out point for ships
			::continue2::
		end

		-- goto marker so things can bail out to here if that iteration isn't valid.
		::continue::
	end

	local totalQuantity = 0
	local entityBreakdown = ""
	for category,quantity in pairs(removedEntityCount) do
		totalQuantity = totalQuantity + quantity
		if quantity > 0 then
			entityBreakdown = entityBreakdown .. quantity .. " " .. category .. ", "
		end
	end
	entityBreakdown = entityBreakdown .. totalQuantity .. " entities in total."

	if totalQuantity > 0 then
		returnValue = commandName .. ": successfully cleared (" .. sectorX .. ":" .. sectorY .. ") of trash, removing " .. entityBreakdown
		print( player.name .. " ran " .. returnValue )
		return 0, returnValue, returnValue
	else
		returnValue = commandName .. ": nothing removable was found in (" .. sectorX .. ":" .. sectorY .. ")"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end
end