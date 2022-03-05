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
		if entity.isStation then -- we only want to do our logic for stations that have been destroyed. anything else is pointless

			local oldOwner = Faction(oldFactionIndex)
			local newOwner = Faction(newFactionIndex)
			local sector = Sector()
			local sectorX, sectorY = sector:getCoordinates()

			if ends_with(oldOwner.name," Pirates") then
				-- pirate faction, do nothing
			else
				 -- non-pirate station that was stolen.
				local server = Server()

				outgoingMessage = "An NPC station was boarded in ("..sectorX..":"..sectorY..") by " .. formatFactionName(newOwner.name) .. "!"

				print("rglx_ServerLib_LogStationDestruction: ".. outgoingMessage)

				-- send notification to all online admins

				local onlinePlayers = { server:getOnlinePlayers() } -- table wrapped to make it nice and iteratable

				for key, playerObject in pairs(onlinePlayers) do
					if server:hasAdminPrivileges(playerObject) then
						playerObject:sendChatMessage("Station Destruction Alerts",2,outgoingMessage)
					end
				end

				rglxServerLibLogStationDestruction.writeTextToFile(outgoingMessage .. "\n\n")

			end
		end
	end

	function rglxServerLibLogStationDestruction.onDestroyed(index,lastDamageInflictor)
		local entity = Entity(index)
		if entity.isStation then -- we only want to do our logic for stations that have been destroyed. anything else is pointless


			local owner = Faction(entity.factionIndex)
			local sector = Sector()
			local sectorX, sectorY = sector:getCoordinates()

			if ends_with(owner.name," Pirates") then -- pirate faction- do nothing.
				--print("rglx_ServerLib_LogStationDestruction: a station owned by ".. owner.name .." was destroyed in ("..sectorX..":"..sectorY.."), but it was a pirate station. ignoring.")
			else -- non-pirate station that has been destroyed. let's get some more information
				local server = Server()

				print("rglx_ServerLib_LogStationDestruction: a station owned by ".. formatFactionName(owner.name) .." was destroyed in ("..sectorX..":"..sectorY..")!")


				-- send notification to all online admins

				local onlinePlayers = { server:getOnlinePlayers() } -- table wrapped to make it nice and iteratable

				for key, playerObject in pairs(onlinePlayers) do
					if server:hasAdminPrivileges(playerObject) then
						playerObject:sendChatMessage("Station Destruction Alerts",2,"An NPC station was destroyed in ("..sectorX..":"..sectorY..")!")
					end
				end


				-- index contents of sector- this may be a bit laggy

				local craftIndexForSector = {}

				local fullListOfAllStations = { sector:getEntitiesByType(EntityType.Station) }
				local fullListOfAllShips = { sector:getEntitiesByType(EntityType.Ship) }

				-- basically all we're doing here is indexing the contents of this sector
				--   	- key for the array is the faction ID
				--  	- value is the number of crafts

				for key, entityObject in pairs(fullListOfAllStations) do
					--print("station for" ..entityObject.factionIndex)
					if craftIndexForSector[entityObject.factionIndex] ~= nil then
						-- faction present in index- increment craft counter up by one.
						craftIndexForSector[entityObject.factionIndex] = craftIndexForSector[entityObject.factionIndex] + 1
					else
						-- faction was not present in index
						craftIndexForSector[entityObject.factionIndex] = 1
					end
				end

				for key, entityObject in pairs(fullListOfAllShips) do
					--print("ship for",entityObject.factionIndex)
					if craftIndexForSector[entityObject.factionIndex] ~= nil then
						-- faction present in index- increment craft counter up by one.
						craftIndexForSector[entityObject.factionIndex] = craftIndexForSector[entityObject.factionIndex] + 1
					else
						-- faction was not present in index
						craftIndexForSector[entityObject.factionIndex] = 1
					end
				end

				--print("index complete- sending")

				-- prep a string to log to file with

				local loggedMessage = "An NPC station was destroyed in ("..sectorX..":"..sectorY..")!\n"

				local lastDamagingFaction = {}
				lastDamagingFaction.index = "[unknown]"
				lastDamagingFaction.name = "[unknown]"

				local lastDamagingEntity = Entity(lastDamageInflictor)
				if lastDamagingEntity ~= nil then
					lastDamagingFaction = Faction(lastDamagingEntity.factionIndex)
				end

				loggedMessage = loggedMessage .. "\tLast known damage inflictor: " .. formatFactionName(lastDamagingFaction.name) .. " (#".. lastDamagingFaction.index .. ")\n"

				loggedMessage = loggedMessage .. "\tContents of ("..sectorX..":"..sectorY..") at time of station destruction:\n"

				for factionId, craftCount in pairs(craftIndexForSector) do
					loggedMessage = loggedMessage .. "\t\t" .. formatFactionName(Faction(factionId).name) .. " (#"..factionId..") - " .. craftCount .. " crafts\n"
					--loggedMessage = loggedMessage .. "\t\tfaction ID #"..factionId.." - " .. craftCount .. " crafts\n"
				end

				-- add an extra newline
				loggedMessage = loggedMessage .. "\n"

				-- remove ridiculous translation strings
				loggedMessage = loggedMessage:gsub(self.stringToRemove,"")

				-- and finally, send it.
				--print(loggedMessage)
				rglxServerLibLogStationDestruction.writeTextToFile(loggedMessage)
				--print("logged out to file and console.")
			end
		end
	end

	function rglxServerLibLogStationDestruction.writeTextToFile(message)
		local server = Server()
		local logFile = server.folder .. "/stations-destroyed.log"
		local logFileHandle = io.open(logFile,"a+")
		if logFileHandle ~= nil then
			logFileHandle:write("[" .. os.date("%Y-%m-%d %X") .. "]\t" .. message .. "\n")
			io.close(logFileHandle)
		else
			print("rglx_ServerLib_LogStationDestruction: ERROR! could not open log file!")
		end
	end
	print("rglx_ServerLib_LogStationDestruction: loaded into sector scripts.")
else
	print("rglx_ServerLib_LogStationDestruction: dont load this on your client- its for servers only.")
end