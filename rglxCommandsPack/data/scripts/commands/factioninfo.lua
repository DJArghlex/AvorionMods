package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")

commandName = "/factionInfo"
commandDescription = "displays a wide variety of information about a given (or selected ship's) faction"
commandHelp = "[index]"

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

-- https://stackoverflow.com/a/50082540
-- i hate doing this kind of shit
local function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end


function execute(sender, commandName, ...)
	local args = {...}
	local returnValue = nil

	-- forbid client execution
	if onClient() then
		return 1, "Execution on client forbidden.", "Execution on client forbidden."
	end

	-- grab some objects
	local player = Player()
	local server = Server()
	--local sector = Sector() -- anything using Sector() can't be run from the console.
	local galaxy = Galaxy()
	tabCharacter = "\t"

	-- forbid non-admin players and the console from running this command
	if player == nil then
		-- command was run from console.
		player = {}
		player.name = "Console"
	else
		if not server:hasAdminPrivileges(player) then
			returnValue = commandName .. ": You don't have permission."
			print( player.name .. " ran " .. returnValue )
			return 1, returnValue, returnValue
		end
		if args[1] == nil then
			if player.craft then
				if player.craft.selectedObject then
					if player.craft.selectedObject.factionIndex then
						args[1] = player.craft.selectedObject.factionIndex
					end
				end
			end
		end
	end

	-- convert to a number
	local targetFactionIndex = tonumber(args[1])

	-- require the target faction index to be a number
	if targetFactionIndex == nil then
		returnValue = commandName .. ": Please specify a faction index, or target a craft."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- require the target faction index to be a WHOLE number
	if targetFactionIndex % 1 ~= 0 then
		returnValue = commandName .. ": Please specify a whole-number faction index, or target a craft."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local factionInformation = ""

	if galaxy:allianceFactionExists(targetFactionIndex) then
		targetAlliance = Alliance(targetFactionIndex)
		factionInformation = "Information about alliance '" .. targetAlliance.name .. "' (#" .. targetAlliance.index .. "):\n"

		-- list players, denote alliance founder
		factionInformation = factionInformation .. "Membership & online status:\n"
		leader = Player(targetAlliance.leader)
		members = {targetAlliance:getMembers()}
		if server:isOnline(targetAlliance.index) then -- report wether the alliance is considered online by the server.
			factionInformation = factionInformation .. tabCharacter .. "Alliance considered online by simulation."
		end
		for _,memberId in pairs(members) do
			allianceMember = Player(memberId)
			factionInformation = factionInformation .. tabCharacter .. allianceMember.name .. " (#" .. allianceMember.index .. ")"
			if leader.index == allianceMember.index then
				factionInformation = factionInformation .. " [leader]"
			end
			if server:isOnline(allianceMember.index) then
				local sectorX, sectorY = allianceMember:getSectorCoordinates()
				factionInformation = factionInformation .. " [online, in (" .. sectorX .. ":" .. sectorY .. ")]"
			end
			factionInformation = factionInformation .. "\n"
		end

		-- list alliance meta-sectors, if present
		homeX,homeY = targetAlliance:getHomeSectorCoordinates()
		if homeX ~= nil and homeY ~= nil then
			factionInformation = factionInformation .. "Alliance home sector is (" .. homeX .. ":" .. homeY .. ")"
			if galaxy:sectorInRift(homeX,homeY) then
				factionInformation = factionInformation .. " [rift sector!]\n"
			else
				factionInformation = factionInformation .. "\n"
			end
		else
			factionInformation = factionInformation .. "home sector unknown!\n"

		end
		factionInformation = factionInformation .. "Resources and Inventory:\n"
		factionInformation = factionInformation .. tabCharacter .. "Credits: " .. toReadableNumber(targetAlliance.money) .. "\n"
		allianceResources = {targetAlliance:getResources()}
		for i = 1, NumMaterials() do
			if allianceResources[i] > 0 then
				factionInformation = factionInformation .. tabCharacter .. Material(i-1).name .. ": " .. toReadableNumber(allianceResources[i]) .. "\n"
			end
		end
		allianceInventory = targetAlliance:getInventory()
		factionInformation = factionInformation .. tabCharacter .. "Inventory: " .. allianceInventory.occupiedSlots .. "/" .. allianceInventory.maxSlots .. " items\n"

		-- list alliance ship/station counts
		local tmpMaxShips = targetAlliance.maxNumShips
		local tmpMaxStations = targetAlliance.maxNumStations
		if tmpMaxShips == nil then tmpMaxShips = "∞" end
		if tmpMaxStations == nil then tmpMaxStations = "∞" end
		factionInformation = factionInformation .. "Fleet size: " .. targetAlliance.numShips .. "/" .. tmpMaxShips .. " ships, " .. targetAlliance.numStations .. "/" .. tmpMaxStations .. " stations\n" 

	elseif galaxy:playerFactionExists(targetFactionIndex) then
		targetPlayer = Player(targetFactionIndex)

		-- player name, index, playtime, online status
		factionInformation = "Information about player '" .. targetPlayer.name .. "' (#" .. targetPlayer.index .. "):\n"

		-- steamID (and steam name if it differs)
		if targetPlayer.name ~= targetPlayer.id.name then
			-- steam name and player's faction name differ.
			factionInformation = factionInformation .. tabCharacter .. "steamID: " .. targetPlayer.id.id .. " (" .. targetPlayer.id.name .. ")\n"
		else
			-- steam name is the same as the faction name
			factionInformation = factionInformation .. tabCharacter .. "steamID: " .. targetPlayer.id.id .. "\n"
		end

		if server:isOnline(targetPlayer.index) then
			factionInformation = factionInformation .. tabCharacter .. "currently playing, " .. round(targetPlayer.playtime/3600, 1) .. " hours of playtime\n"
		else
			factionInformation = factionInformation .. tabCharacter .. "not online, " .. round(targetPlayer.playtime/3600, 1) .. " hours of playtime\n"
		end

		-- player DLC ownership
		factionInformation = factionInformation .. "has DLCs: "
		ownedDLCs = {}
		if targetPlayer.ownsBlackMarketDLC then
			table.insert(ownedDLCs, "Black Market")
		end
		if targetPlayer.ownsIntoTheRiftDLC then
			table.insert(ownedDLCs, "Into The Rift")
		end

		if ownedDLCs == {} then
			factionInformation = factionInformation .. "[none]"
		else
			for _,dlc in pairs(ownedDLCs) do
				factionInformation = factionInformation .. dlc .. " | "
			end
		end
		factionInformation = factionInformation .. "\n"

		-- get some information about the player's meta-sectors
		sectorX,sectorY = targetPlayer:getSectorCoordinates()
		respawnX,respawnY = targetPlayer:getRespawnSiteCoordinates()
		reconX,reconY = targetPlayer:getReconstructionSiteCoordinates()
		homeX,homeY = targetPlayer:getHomeSectorCoordinates()

		if sectorX ~= nil and sectorY ~= nil then
			factionInformation = factionInformation .. "currently in (" .. sectorX .. ":" .. sectorY .. ")"
			if galaxy:sectorInRift(sectorX,sectorY) then
				factionInformation = factionInformation .. " [rift sector!]\n"
			else
				factionInformation = factionInformation .. "\n"
			end
		else
			factionInformation = factionInformation .. "current location unknown!\n"
		end

		if homeX ~= nil and homeY ~= nil then
			factionInformation = factionInformation .. tabCharacter .. "initial start is (" .. homeX .. ":" .. homeY .. ")"
			if galaxy:sectorInRift(homeX,homeY) then
				factionInformation = factionInformation .. " [rift sector!]\n"
			else
				factionInformation = factionInformation .. "\n"
			end
		else
			factionInformation = factionInformation .. "home sector unknown!\n"

		end

		if reconX ~= nil and reconY ~= nil then
			factionInformation = factionInformation .. tabCharacter .. "reconstruction site is (" .. reconX .. ":" .. reconY .. ")"
			if galaxy:sectorInRift(reconX,reconY) then
				factionInformation = factionInformation .. " [rift sector!]\n"
			else
				factionInformation = factionInformation .. "\n"
			end
		else
			factionInformation = factionInformation .. "reconstruction sector unknown!\n"
		end

		if respawnX ~= nil and respawnY ~= nil then
			factionInformation = factionInformation .. tabCharacter .. "respawns in (" .. respawnX .. ":" .. respawnY .. ")"
			if galaxy:sectorInRift(respawnX,respawnY) then
				factionInformation = factionInformation .. " [rift sector!]\n"
			else
				factionInformation = factionInformation .. "\n"
			end
		else
			factionInformation = factionInformation .. "respawn location unknown!\n"
		end


		-- get some information about the player's resources and inventory
		
		factionInformation = factionInformation .. "Resources and Inventory:\n"
		factionInformation = factionInformation .. tabCharacter .. "Credits: " .. toReadableNumber(targetPlayer.money) .. "\n"
		playerResources = {targetPlayer:getResources()}
		for i = 1, NumMaterials() do
			if playerResources[i] > 0 then
				factionInformation = factionInformation .. tabCharacter .. Material(i-1).name .. ": " .. toReadableNumber(playerResources[i]) .. "\n"
			end
		end
		playerInventory = targetPlayer:getInventory()
		factionInformation = factionInformation .. tabCharacter .. "Inventory: " .. playerInventory.occupiedSlots .. "/" .. playerInventory.maxSlots .. " items\n"
		factionInformation = factionInformation .. tabCharacter .. "Mailbox: " .. targetPlayer.numMails .. "/" .. targetPlayer.maxNumMails .. " game-mails\n"

		-- game progression. max sockets, usable materials, if they've been in the barrier yet
		factionInformation = factionInformation .. "Maximum ship socket size: " .. targetPlayer.maxBuildableSockets .. " sockets\n"
		factionInformation = factionInformation .. "Material capability: " .. targetPlayer.maxBuildableMaterial.name .. "\n"

		-- list player ship/station counts
		local tmpMaxShips = targetPlayer.maxNumShips
		local tmpMaxStations = targetPlayer.maxNumStations
		if tmpMaxShips == nil then tmpMaxShips = "∞" end
		if tmpMaxStations == nil then tmpMaxStations = "∞" end
		factionInformation = factionInformation .. "Fleet size: " .. targetPlayer.numShips .. "/" .. tmpMaxShips .. " ships, " .. targetPlayer.numStations .. "/" .. tmpMaxStations .. " stations\n" 

		-- get some information about the player's alliance membership.
		if targetPlayer.alliance ~= nil then
			if #{targetPlayer.alliance:getMembers()} == 1 then
				factionInformation = factionInformation .. "Sole member of alliance '" .. targetPlayer.alliance.name .. "' (#" .. targetPlayer.alliance.index .. ")\n"
			else
				if targetPlayer.alliance.leader == targetPlayer.index then 
					factionInformation = factionInformation .. "Leader of " .. #{targetPlayer.alliance:getMembers()} .. "-player alliance '" .. targetPlayer.alliance.name .. "' (#" .. targetPlayer.alliance.index .. ")\n"
				else
					factionInformation = factionInformation .. "Member of " .. #{targetPlayer.alliance:getMembers()} .. "-player alliance '" .. targetPlayer.alliance.name .. "' (#" .. targetPlayer.alliance.index .. ")\n"
				end
			end
		else
			factionInformation = factionInformation .. "Not in an alliance.\n"
		end

		-- get some information about the player's group, if they have one
		if targetPlayer.group ~= nil then
			-- list players, denote leader, show number of members in the group 
			factionInformation = factionInformation .. "In a " .. targetPlayer.group.size .. "-player group with:\n"
			for _,playerId in pairs({targetPlayer.group:getPlayers()}) do
				-- for each playerID in the group, get their name, and if they're online or not.
				groupPlayer = Player(playerId)
				if targetPlayer.group.leader == groupPlayer.index then -- denote "leader" player of group
					factionInformation = factionInformation .. tabCharacter .. groupPlayer.name .. " (#" .. groupPlayer.index .. ") [leader]\n"
				else
					factionInformation = factionInformation .. tabCharacter .. groupPlayer.name .. " (#" .. groupPlayer.index .. ")\n"
				end
			end

		else
			factionInformation = factionInformation .. "Not in a group.\n"
		end

	elseif galaxy:aiFactionExists(targetFactionIndex) then
		targetNpcFaction = Faction(targetFactionIndex)
		factionInformation = "Information about NPC Faction '" .. targetNpcFaction.name .. "' (#" .. targetNpcFaction.index .. "):\n"


		-- get some information about the player's meta-sectors
		homeX,homeY = targetNpcFaction:getHomeSectorCoordinates()

		if homeX ~= nil and homeY ~= nil then
			factionInformation = factionInformation .. tabCharacter .. "headquarters sector is (" .. homeX .. ":" .. homeY .. ")"
			if galaxy:sectorInRift(homeX,homeY) then
				factionInformation = factionInformation .. " [rift sector!]\n"
			else
				factionInformation = factionInformation .. "\n"
			end
		else
			factionInformation = factionInformation .. "home sector unknown!\n"

		end

		-- get information about faction traits
		if targetNpcFaction.getTraits ~= nil then
			local factionTraits = targetNpcFaction:getTraits()
			if factionTraits == nil then
				factionInformation = factionInformation .. "Faction has no behavioral traits.\n"
			else
				local factionBehavioralTraits = "Faction behavioral traits:\n"
				local factionBehavioralValues = 0
				for trait, potency in pairs(factionTraits) do
					if tonumber(potency) < 0 then
						factionBehavioralValues = factionBehavioralValues + 1
						factionBehavioralTraits = factionBehavioralTraits .. tabCharacter .. trait .. ": " .. math.floor( tonumber(potency) * 100) .. "%\n"
					end
				end
				if factionBehavioralValues > 0 then
					factionInformation = factionInformation .. factionBehavioralTraits
				else
					factionInformation = factionInformation .. "Faction has no behavioral traits.\n"
				end
			end
		else
			factionInformation = factionInformation .. "Faction has no behavioral traits.\n"
		end


		-- find what factions this one's at war with, excluding pirates
		local npcFactionRelations = {targetNpcFaction:getAllRelations()}
		if npcFactionRelations == {} then
			factionInformation = factionInformation .. "Faction has no relations with other NPC factions."
		else
			factionInformation = factionInformation .. "Faction relations:\n"
			local validFactions = 10 -- change this number to adjust how many NPC factions to report relations back to
			for _,relation in pairs(npcFactionRelations) do
				if galaxy:aiFactionExists(relation.factionIndex) then
					validFactions = validFactions - 1
					if validFactions > 0 then
						-- only run Faction() calls and append to this list if we've not gone over the set limit of information to report
						relatedFaction = Faction(relation.factionIndex)
						factionInformation = factionInformation .. tabCharacter .. relation.translatedStatus .. " with " .. relatedFaction.name .. " (#" .. relation.factionIndex .. ") [" .. relation.level .. " pts]\n"
					end
				end
			end
			if validFactions < 0 then
				-- if we have gone negative, this means the list is now X items long, and we should report back that there are more than that many relations to other factions.
				factionInformation = factionInformation .. tabCharacter .. "[... and " .. validFactions * -1 .. " more faction relations]"
			end
		end

	else
		returnValue = commandName .. ": No faction found with this index. Try another index, or select a target."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue

	end


	returnValue = commandName .. ": " .. factionInformation
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end