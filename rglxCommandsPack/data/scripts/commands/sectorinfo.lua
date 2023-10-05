local commandName = "/sectorInfo"
local commandDescription = "Lists information about the sector you're presently in."
local commandHelp = "[values/scripts] - optionally list either sector values or sector scripts instead of sector contents"

-- used for determining generation templates of a sector
package.path = package.path .. ";data/scripts/?.lua"
local SectorSpecifics = include ("sectorspecifics")

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

-- "patch" 2.0 release bug that irreversibly added this to all the generated names in the galaxy.
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
	--print(args[1])
	local playerId = tonumber(args[1])
	local returnValue = nil

	local player = Player()
	local server = Server()
	local galaxy = Galaxy()

	-- modifiable formatting helpers
	local newLine = "\n"
	local tabCharacter = "\t"


	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	-- we also want to independently of the normal permissions system, restrict this to administrators.
	if player == nil then
		player = {}
		player.name = "Console"
	elseif not server:hasAdminPrivileges(player) then
		returnValue = commandName .. ": You don't have permission."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local sector = Sector()
	local sectorX, sectorY = sector:getCoordinates()

	if args[1] == "scripts" or args[1] == "s" then
		-- list sectorwide scripts
		returnValue = commandName .. ": Scripts loaded into '" .. sector.name .. "':"
		for id, script in ipairs(sector:getScripts()) do
			returnValue = returnValue .. newLine .. tabCharacter .. "#" .. id .. ": " .. tabCharacter .. script
		end
	elseif args[1] == "values" or args[1] == "v" then
		-- return all sector values, attempting to convert them to strings.
		returnValue = commandName .. ": Values set by scripts on '" .. sector.name .. "':"
		for valueName, value in ipairs(sector:getValues()) do
			local valueContents = nil
			if value == nil then
				valueContents = "nil"
			elseif tostring(value) == nil then
				valueContents = "[non-stringable]"
			else
				valueContents = tostring(value)
			end
			returnValue = returnValue .. newLine .. tabCharacter .. valueName .. ": " .. tabCharacter .. tostring(valueContents) .. "[" .. type(value) .. "]"
		end
	else

		-- rift status, sector name, coordinates
		-- generation template
		-- controlling faction
		-- contents breakdown:
		--    - fighters, wreckages, items
		--    - asteroids, stations, ships
		-- control breakdown:
		--    - faction type, name, ID
		--    - ship/station count, caps, and galaxywide count

		-- okay. let's start getting some basic info about the sector
		returnValue = commandName .. ": Sector information about '" .. sector.name .. "':" .. newLine .. "location: (" .. sectorX .. ":" .. sectorY .. ")"

		-- is it a rift sector?
		if galaxy:sectorInRift(sectorX,sectorY) then
			returnValue = returnValue .. " [in rift!]"
		end

		-- current controller, if known
		local controllingFaction = galaxy:getControllingFaction(sectorX,sectorY)
		if controllingFaction == nil then
			returnValue = returnValue .. newLine .. "not controlled by a faction."
		else
			returnValue = returnValue .. newLine .. "control exerted by " .. formatFactionName(controllingFaction.name) .. " (#" .. controllingFaction.index .. ")"
		end

		-- generation template
		local specs = SectorSpecifics(sectorX, sectorY, GameSeed())
		if specs.generationTemplate then
			returnValue = returnValue .. newLine .. "generation template: " .. specs.generationTemplate.path
		else
			returnValue = returnValue .. newLine .. "no generation template."
		end

		-- index the contents of the sector
		local factionShips = {} -- by factionID list of ships
		local factionStations = {} -- by-factionID list of stations
		local sectorIndex = {}

		-- get all entities in the sector
		local fullEntityList = {sector:getEntities()}

		-- iterate through each entity in the list
		for _,entity in ipairs(fullEntityList) do
			-- add one to that entity type's counter (or set as one if the counter doesn't exist)
			if sectorIndex[entity.typename] == nil then
				sectorIndex[entity.typename] = 1
			else
				sectorIndex[entity.typename] = sectorIndex[entity.typename] + 1
			end
			if entity.type == EntityType.Ship then
				-- add to this entity's factionindex counter for ships
				if factionShips[entity.factionIndex] == nil then
					factionShips[entity.factionIndex] = 1
				else
					factionShips[entity.factionIndex] = factionShips[entity.factionIndex] + 1
				end
			elseif entity.type == EntityType.Station then
				-- add to this entity's factionindex counter for stations
				if factionStations[entity.factionIndex] == nil then
					factionStations[entity.factionIndex] = 1
				else
					factionStations[entity.factionIndex] = factionStations[entity.factionIndex] + 1
				end
			end
		end

		-- now make our reports
		-- starting with the general contents
		returnValue = returnValue .. newLine .. "sector entity list: "
		for category,count in pairs(sectorIndex) do
			--print(category,count)
			-- reformat and pluralize a bit
			if category == "None" then
				tmpCategory = "unclassified"
			elseif category == "Anomaly" then
				tmpCategory = "anomalies"
			elseif category == "Loot" then
				tmpCategory = "items"
			elseif category == "Torpedo" then
				tmpCategory = "torpedoes"
			else
				tmpCategory = string.lower(category) .. "s"
			end
			returnValue = returnValue .. count .. " " .. tmpCategory .. ", "
		end
		-- remove last two characters from string
		returnValue = returnValue:sub(1, -3)

		returnValue = returnValue .. newLine .. "ships in sector:"
		for factionIndex,count in pairs(factionShips) do
			local owningFaction = nil
			-- determine owning faction's type
			if galaxy:playerFactionExists(factionIndex) then
				-- player faction
				owningFaction = Player(factionIndex)
				returnValue = returnValue .. newLine .. tabCharacter .. count .. " ships of player " .. formatFactionName(owningFaction.name) .. " (#" .. owningFaction.index .. ") shipcap: " .. owningFaction.numShips .. "/" ..  owningFaction.maxNumShips
			elseif galaxy:allianceFactionExists(factionIndex) then
				owningFaction = Alliance(factionIndex)
				returnValue = returnValue .. newLine .. tabCharacter .. count .. " ships of alliance " .. formatFactionName(owningFaction.name) .. " (#" .. owningFaction.index .. ") shipcap: " .. owningFaction.numShips .. "/" ..  owningFaction.maxNumShips
			elseif galaxy:aiFactionExists(factionIndex) then
				owningFaction = Faction(factionIndex)
				returnValue = returnValue .. newLine .. tabCharacter .. count .. " ships of NPC " .. formatFactionName(owningFaction.name) .. " (#" .. owningFaction.index .. ")" .. ", "
			else
				eprint("WARNING: ship with unknown faction ownership detected in (" .. sectorX .. ":" .. sectorY .. ")!")
			end
		end
		-- remove trailing comma and space
		--returnValue = returnValue:sub(1, -3)

		local stationIndexText = ""
		local stationCountInSector = 0
		for factionIndex,count in pairs(factionStations) do
			stationCountInSector = stationCountInSector + count -- increment counter
			local owningFaction = nil
			-- determine owning faction's type
			if galaxy:playerFactionExists(factionIndex) then
				-- player faction
				owningFaction = Player(factionIndex)
				stationIndexText = stationIndexText .. newLine .. tabCharacter .. count .. " stations of player " .. formatFactionName(owningFaction.name) .. " (#" .. owningFaction.index .. ") stationcap: " .. owningFaction.numStations .. "/" ..  owningFaction.maxNumStations
			elseif galaxy:allianceFactionExists(factionIndex) then
				owningFaction = Alliance(factionIndex)
				stationIndexText = stationIndexText .. newLine .. tabCharacter .. count .. " stations of alliance " .. formatFactionName(owningFaction.name) .. " (#" .. owningFaction.index .. ") stationcap: " .. owningFaction.numStations .. "/" ..  owningFaction.maxNumStations
			elseif galaxy:aiFactionExists(factionIndex) then
				owningFaction = Faction(factionIndex)
				stationIndexText = stationIndexText .. newLine .. tabCharacter .. count .. " stations of NPC " .. formatFactionName(owningFaction.name) .. " (#" .. owningFaction.index .. ")"
			else
				eprint("WARNING: ship with unknown faction ownership detected in (" .. sectorX .. ":" .. sectorY .. ")!")
			end
		end
		returnValue = returnValue .. newLine .. "stations in sector (" .. stationCountInSector .. "/" .. GameSettings().maximumStationsPerSector .. " in sector):" .. stationIndexText
		-- remove trailing comma and space
		--returnValue = returnValue:sub(1, -3)

	end

	-- and return to the executing player.
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue

end