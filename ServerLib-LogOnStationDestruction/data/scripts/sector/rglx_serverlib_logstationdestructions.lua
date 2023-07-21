-- namespace rglxServerLibLogStationDestruction
rglxServerLibLogStationDestruction = {}
local self = rglxServerLibLogStationDestruction

self.stringToRemove = "/*This refers to factions, such as 'The Xsotan'.*/"

if onServer() then

	-- http://lua-users.org/wiki/StringRecipes
	local function ends_with(str, ending)
		return ending == "" or str:sub(-#ending) == ending
	end

	local function formatFactionName(factionName)
		if ends_with(factionName, self.stringToRemove) then
			return string.sub(factionName,1,( -1 - string.len(self.stringToRemove)))
		else
			return factionName
		end
	end

	function rglxServerLibLogStationDestruction.initialize()
		local sector = Sector()
		-- register callbacks for entity destruction in the sector
		sector:registerCallback("onDestroyed", "onDestroyed")
		sector:registerCallback("onBoardingSuccessful", "onBoardingSuccessful")
	end

	function rglxServerLibLogStationDestruction.onBoardingSuccessful(index,oldFactionIndex,newFactionIndex)
		local entity = Entity(index)

		-- ignore entities that don't exist
		if not entity then eprint("rglx_ServerLib_LogStationDestruction: onBoardingSuccessful callback fired for nil entity! (#4)") return end
		
		-- ignore non-stations
		if not entity.isStation then return end

		-- determine station's previous owner
		local oldOwner = Faction(oldFactionIndex)

		-- ignore non-NPC factions
		if not oldOwner.isAIFaction then return end

		-- ignore pirate NPCs specifically
		if ends_with(oldOwner.name," Pirates") then return end

		-- ignore Black Market DLC's Family questline station that gets blown up
		if oldOwner.name == "Jackson" then return end

		-- ok! it's a non-player/alliance, non-pirate station that was boarded. let's make the report


		-- make sure we're not doing a bunch of legwork for bad data or misfiring callbacks...
		local boardingFaction = Faction(newFactionIndex)
		if boardingFaction == nil then
			eprint("rglx_ServerLib_LogStationDestruction: onBoardingSuccessful callback fired with nil boardingFaction! (#4)")
			return
		end

		local previousOwner = Faction(oldFactionIndex)

		-- and finally, call the report-making function.
		self.generateReport(entity,boardingFaction,previousOwner)

	end

	function rglxServerLibLogStationDestruction.onDestroyed(index,lastDamageInflictor)
		local entity = Entity(index)

		-- ignore entities that don't exist
		if not entity then eprint("rglx_ServerLib_LogStationDestruction: onDestroyed callback fired for nil entity! (#1)") return end

		-- ignore non-stations
		if not entity.isStation then return end


		local owner = Faction(entity.factionIndex)

		-- ignore non-NPC factions
		if not owner.isAIFaction then return end

		-- ignore pirate stations
		if ends_with(owner.name," Pirates") then return end

		-- ignore Black Market DLC's Family questline station that gets blown up
		if owner.name == "Jackson" then return end
		
		-- ok! it's a non-player/alliance, non-pirate station that was destroyed. let's make the report.

		-- make sure we're not doing a bunch of legwork for bad data or misfiring callbacks...
		local lastDamagingEntity = Entity(lastDamageInflictor)
		if lastDamagingEntity ~= nil then
			lastDamagingFaction = Faction(lastDamagingEntity.factionIndex)
			if lastDamagingFaction == nil then
				eprint("rglx_ServerLib_LogStationDestruction: onDestroyed callback fired with lastDamagingFaction as nil! (#3)")
				return
			end
		else
			eprint("rglx_ServerLib_LogStationDestruction: onDestroyed callback fired with lastDamagingEntity.factionIndex as nil! (#2)")
			return
		end

		-- and finally, call the report-making function.
		self.generateReport(entity,lastDamagingFaction,false)

	end

	function rglxServerLibLogStationDestruction.generateReport(entity,enemyFaction,previousOwner)
		-- Entity(), Faction(), Faction() or false

		-- get some variables setup
		local destructionType = "destroyed"
		if previousOwner ~= false then destructionType = "boarded" end
		local sector = Sector()
		local server = Server()
		local sectorX, sectorY = sector:getCoordinates()

		local oneLineMessage = "An NPC station was " .. destructionType .. " in ("..sectorX..":"..sectorY..") by "..formatFactionName(enemyFaction.name).."! (#" .. enemyFaction.index ..")"

		-- send notification to all online admins
		local onlinePlayers = { server:getOnlinePlayers() } -- table wrapped to make it nice and iteratable

		for key, playerObject in pairs(onlinePlayers) do
			if server:hasAdminPrivileges(playerObject) then
				playerObject:sendChatMessage("Station Destruction Alerts",2,oneLineMessage)
			end
		end

		-- index contents of sector- this may be a bit laggy

		local craftIndexForSector = {}

		local fullListOfAllStations = { sector:getEntitiesByType(EntityType.Station) }
		local fullListOfAllShips = { sector:getEntitiesByType(EntityType.Ship) }

		-- iterate through stations
		for key, entityObject in pairs(fullListOfAllStations) do
			--print("station for " ..entityObject.factionIndex)
			if craftIndexForSector[entityObject.factionIndex] ~= nil then
				-- faction present in index- increment craft counter up by one.
				craftIndexForSector[entityObject.factionIndex] = craftIndexForSector[entityObject.factionIndex] + 1
			else
				-- faction was not present in index
				craftIndexForSector[entityObject.factionIndex] = 1
			end
		end

		-- iterate through ships
		for key, entityObject in pairs(fullListOfAllShips) do
			--print("ship for ",entityObject.factionIndex)
			if craftIndexForSector[entityObject.factionIndex] ~= nil then
				-- faction present in index- increment craft counter up by one.
				craftIndexForSector[entityObject.factionIndex] = craftIndexForSector[entityObject.factionIndex] + 1
			else
				-- faction was not present in index
				craftIndexForSector[entityObject.factionIndex] = 1
			end
		end


		print("rglx_ServerLib_LogStationDestruction: ".. oneLineMessage)


		-- prep a string to log to file with

		local loggedMessage = oneLineMessage .. "\n"


		if previousOwner ~= false then
			loggedMessage = loggedMessage .. "\tStation class: " .. formatFactionName(entity.title) .. "\n" -- shows up as "defunct station" in all cases
			loggedMessage = loggedMessage .. "\tStation name: " .. formatFactionName(entity.name) .. "\n"
			loggedMessage = loggedMessage .. "\tStation owner: " .. formatFactionName(previousOwner.name) .. "\n"
			loggedMessage = loggedMessage .. "\tBoarding faction: " .. formatFactionName(enemyFaction.name) .. " (#".. enemyFaction.index .. ")\n"
		else
			loggedMessage = loggedMessage .. "\tStation class: " .. formatFactionName(entity.title) .. "\n"
			loggedMessage = loggedMessage .. "\tStation name: " .. formatFactionName(entity.name) .. "\n"
			loggedMessage = loggedMessage .. "\tStation owner: " .. formatFactionName(Faction(entity.factionIndex).name) .. "\n"
			loggedMessage = loggedMessage .. "\tLast known damage inflictor: " .. formatFactionName(enemyFaction.name) .. " (#".. enemyFaction.index .. ")\n"
		end

		loggedMessage = loggedMessage .. "\tContents of ("..sectorX..":"..sectorY..") at the time:\n"

		for factionId, craftCount in pairs(craftIndexForSector) do
			loggedMessage = loggedMessage .. "\t\t" .. formatFactionName(Faction(factionId).name) .. " (#"..factionId..") - " .. craftCount .. " crafts\n"
			--loggedMessage = loggedMessage .. "\t\tfaction ID #"..factionId.." - " .. craftCount .. " crafts\n"
		end

		-- add an extra newline
		loggedMessage = loggedMessage .. "\n"

		-- remove ridiculous translation strings
		loggedMessage = loggedMessage:gsub(self.stringToRemove,"")

		-- and finally, send it.
		rglxServerLibLogStationDestruction.writeTextToFile(loggedMessage)


	end

	function rglxServerLibLogStationDestruction.writeTextToFile(message)
		local server = Server()
		local logFile = server.folder .. "/stations-destroyed.log"
		local logFileHandle = io.open(logFile,"a+")
		if logFileHandle ~= nil then
			logFileHandle:write("[" .. os.date("%Y-%m-%d %X") .. "]\t" .. message .. "\n")
			io.close(logFileHandle)
		else
			eprint("rglx_ServerLib_LogStationDestruction: ERROR! could not open log file!")
		end
	end
else
	print("rglx_ServerLib_LogStationDestruction: dont load this on your client- its for servers only.")
end