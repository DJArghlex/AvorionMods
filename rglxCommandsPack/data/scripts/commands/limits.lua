package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/limits"
commandDescription = "Shows the galaxy's current limits."
commandHelp = ""

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function comma_value(amount) -- from http://lua-users.org/wiki/FormattingNumbers
	local formatted = amount
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

local function lines_from(file) -- https://stackoverflow.com/questions/11201262/
	lines = {}
	for line in io.lines(file) do 
		lines[#lines + 1] = line
	end
	return lines
end

local function stringStartsWith(haystack, needle)
	return haystack:find(needle, 1, true) ~= nil
end

local function readIniFileToTable(filename)
	-- i hate that i have to write an ini parser for things that should just be present in the GameSettings()
	local sectionName = "default"
	local returnedTable = {} -- create main table
	returnedTable[sectionName] = {} -- create sub-table

	local rawServerConfig = lines_from(filename)
	for k,v in pairs(rawServerConfig) do
		if stringStartsWith(v,"[") then
			sectionName = string.match(v,"^%[(.*)%]$")
			returnedTable[sectionName] = {} -- create sub-table
			--print ("new section: " .. sectionName)
		elseif stringStartsWith(v,";") then
			--print ("skipping a comment")
		else
			local directiveName, directiveValue = string.match(v,"^(.*)=(.*)$")
			if directiveName ~= nil and directiveValue ~= nil then
				if tonumber(directiveValue) ~= nil then
					returnedTable[sectionName][directiveName] = tonumber(directiveValue)
				else
					returnedTable[sectionName][directiveName] = directiveValue
				end
			end
		end
	end

	return returnedTable
end

function execute(sender, commandName, ...)
	local args = ...
	local player = Player()
	local returnValue = nil

	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end
	
	
	local gameSettingsObject = GameSettings()
	local serverSettingsObject = Server()
	local serverConfig = readIniFileToTable(serverSettingsObject.folder .. "/server.ini")

	returnValue = "Galactic limits are as follows:\n"

	-- maximum ship and station volume
	if gameSettingsObject.unlimitedShipSize then
		-- ship size limit is by volume.


		returnValue = returnValue .. "Ship & Station size limit: by volume:\n"
		if gameSettingsObject.maximumVolumePerShip > 0 then
			returnValue = returnValue .. "    Ships: " .. comma_value(gameSettingsObject.maximumVolumePerShip) .. " m³\n"
		else
			returnValue = returnValue .. "    Ships: unlimited\n"
		end

		-- station volume limits
		if gameSettingsObject.maximumVolumePerStation > 0 then
			returnValue = returnValue .. "    Stations: " .. comma_value(gameSettingsObject.maximumVolumePerStation) .. " m³\n"
		else
			returnValue = returnValue .. "    Stations: unlimited\n"
		end

	else
		-- 
		returnValue = returnValue .. "Ship/Station size limit: by processing power.\n"
	end

	-- construction limitations

	-- minimum craft size limit
	if serverConfig["Game"]["MinimumCraftSize"] > 0 then
		returnValue = returnValue .. "    Minimum ship dimensions: " .. comma_value( (serverConfig["Game"]["MinimumCraftSize"] / 10 ) ) .. " build unit(s) in any direction\n"
	end
	-- retro block stacking
	if serverConfig["Game"]["BlockOverlapExploit"] == "true" then
		returnValue = returnValue .. "    Stacked blocks: allowed\n"
	else
		returnValue = returnValue .. "    Stacked blocks: forbidden\n"
	end
	if serverConfig["Game"]["DockingRestrictions"] == "true" then
		returnValue = returnValue .. "    Docking restrictions: in place\n"
	else
		returnValue = returnValue .. "    Docking restrictions: rescinded\n"
	end


	-- block limits
	returnValue = returnValue .. "Block count limits:\n"
	if gameSettingsObject.maximumBlocksPerCraft > 0 then
		returnValue = returnValue .. "    Ships & Stations: " .. comma_value(gameSettingsObject.maximumBlocksPerCraft) .. " blocks\n"
	else
		returnValue = returnValue .. "    Ships & Stations: unlimited\n"
	end

	if serverConfig["Game"]["MaximumBlocksPerTurret"] > 0 then
		returnValue = returnValue .. "    Turret Designs: " .. comma_value(serverConfig["Game"]["MaximumBlocksPerTurret"]) .. " blocks\n"
	else
		returnValue = returnValue .. "    Turret Designs: unlimited\n"
	end
	-- until this is configurable...
	returnValue = returnValue .. "    Fighter Skins: 200 blocks\n"

	-- ship counts (personal)
	returnValue = returnValue .. "Fleet limits:\n"


	if gameSettingsObject.maximumPlayerShips > 0 then
		returnValue = returnValue .. "    Personal ships: " .. comma_value(gameSettingsObject.maximumPlayerShips) .. " ships\n"
	else
		returnValue = returnValue .. "    Personal ships: unlimited\n"
	end
	if gameSettingsObject.maximumPlayerStations > 0 then
		returnValue = returnValue .. "    Personal stations: " .. comma_value(gameSettingsObject.maximumPlayerStations) .. " stations\n"
	else
		returnValue = returnValue .. "    Personal stations: unlimited\n"
	end

	-- the per-member alliance limit settings, as explained in server.ini's example file work out like this:
	-- if set, each member you have in an alliance's roster add that many maximum slots to whichever category.
	-- so, with maximumAllianceShipsPerMember set to 5, and maximumAllianceShips set to 30, 
	-- each member would add five slots, with a maximum of 30 to that alliance's maximum ship count,
	-- essentially enforcing the paradigm that 'more people is better'.


	if gameSettingsObject.maximumAllianceShipsPerMember > 0 then
		if gameSettingsObject.maximumAllianceShips > 0 then
			returnValue = returnValue .. "    Alliance ships: " .. comma_value(gameSettingsObject.maximumAllianceShipsPerMember) .. " ships per alliance member\n"
			returnValue = returnValue .. "        Maximum alliance ships: " .. comma_value(gameSettingsObject.maximumAllianceShips) .. " total alliance ships\n"
		else
			returnValue = returnValue .. "    Alliance ships: " .. comma_value(gameSettingsObject.maximumAllianceShipsPerMember) .. " ships per alliance member\n"
		end
	else
		if gameSettingsObject.maximumAllianceStations > 0 then
			returnValue = returnValue .. "    Alliance ships: " .. comma_value(gameSettingsObject.maximumAllianceStations) .. " ships\n"
		else
			returnValue = returnValue .. "    Alliance ships: unlimited\n"
		end
	end

	if gameSettingsObject.maximumAllianceStationsPerMember > 0 then
		if gameSettingsObject.maximumAllianceStations > 0 then
			returnValue = returnValue .. "    Alliance stations: " .. comma_value(gameSettingsObject.maximumAllianceStationsPerMember) .. " stations per alliance member\n"
			returnValue = returnValue .. "        Maximum alliance stations: " .. comma_value(gameSettingsObject.maximumAllianceStations) .. " total alliance stations\n"
		else
			returnValue = returnValue .. "    Alliance stations: " .. comma_value(gameSettingsObject.maximumAllianceStationsPerMember) .. " stations per alliance member\n"
		end
	else
		if gameSettingsObject.maximumAllianceStations > 0 then
			returnValue = returnValue .. "    Alliance stations: " .. comma_value(gameSettingsObject.maximumAllianceStations) .. " stations\n"
		else
			returnValue = returnValue .. "    Alliance stations: unlimited\n"
		end
	end


	-- sector limits
	returnValue = returnValue .. "Sector limits:\n"

	-- maximum stations allowed in a sector
	if gameSettingsObject.maximumStationsPerSector > 0 then
		returnValue = returnValue .. "    Stations: " .. comma_value(gameSettingsObject.maximumStationsPerSector) .. " stations\n"
	else
		returnValue = returnValue .. "    Stations: unlimited\n"
	end

	-- maximum deployed fighters allowed by a player or alliance in a sector
	if gameSettingsObject.maximumFightersPerSectorAndPlayer > 0 then
		returnValue = returnValue .. "    Fighters per player/alliance: " .. comma_value(gameSettingsObject.maximumFightersPerSectorAndPlayer) .. " fighters\n"
	else
		returnValue = returnValue .. "    Fighters per player/alliance: unlimited\n"
	end

	-- maximum sectors that will be simulated (either fully or partially) by the server
	if serverConfig["System"]["aliveSectorsPerPlayer"] > 0 then
		returnValue = returnValue .. "    Alive sectors per player: " .. comma_value(serverConfig["System"]["aliveSectorsPerPlayer"]) .. " sectors (including alliance)\n"
	else
		returnValue = returnValue .. "    Alive sectors per player: unlimited\n"
	end

	-- maximum sectors to subject to the Invasion in the core
	if serverSettingsObject.xsotanInvasionSectors > 0 then
		returnValue = returnValue .. "    Xsotan invasion sector targets: " .. comma_value(serverSettingsObject.xsotanInvasionSectors) .. " sectors within the Barrier\n"
	else
		returnValue = returnValue .. "    Xsotan invasion sector targets: Any within the Barrier\n"
	end

	print( player.name .. " requested galaxy's current limits.")
	return 0, returnValue, returnValue
end