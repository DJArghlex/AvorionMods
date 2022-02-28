local commandName = "/listAllPlayerCraftsToFile"
local commandDescription = "Lists all player crafts, their locations, and numerous other details to a file in the server's galaxy folder."
local commandHelp = ""

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function has_value (tab, val) -- https://stackoverflow.com/a/33511182
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function execute(sender, commandName, ...)
	local args = {...}
	--print(args[1])
	local playerId = tonumber(args[1])
	local returnValue = nil

	local player = Player()
	local server = Server()
	local galaxy = Galaxy()

	local sep = "	"
	local fileToWrite = server.folder .. "/craftslisting.tsv"

	local alreadyIteratedAlliances = {}
	local fullCraftListing = {}

	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		player = {}
		player.name = "Console"
	end

	print(" *** *** *** ALERT! *** *** *** Attempting to index, list, and locate ALL player & alliance ships in the entire galaxy - this may take some time. If your players move their ships between now and the time the server saves and shuts down, the information won't be accurate, so do NOT run this with players connected, and shut the server down when it's finished!")

	print ("attempting to fetch a full list of all players who have connected to the galaxy... this can take a little while.")

	-- this one might be the thing that takes the longest, as it actually retrieves player objects for each player, instead of just handing me a big list of indices to wrap Player() around myself - and some servers (looking at you, tree cafe #1) have had more than three thousand players since their last wipe - so this could cause a significant amount of lag or outright kill a server if it takes too long.

	local fullPlayerListing = { server:getPlayers() } -- retrieves all players that have ever been on the server

	print ("player indexing complete - beginning ship indexing")

	for key, playerObject in pairs(fullPlayerListing) do

		-- for each player, we want to get a whole entire list of all their ships
		print("indexing player " .. playerObject.name .. "'s (#" .. playerObject.index .. ") ships...")

		-- now, get a list of their ships
		local thisPlayersShipListing = { playerObject:getShipNames() }
		for key, shipName in pairs(thisPlayersShipListing) do

			-- grab the information we need
			local shipX, shipY = playerObject:getShipPosition(shipName)
			local shipType = playerObject:getShipType(shipName)

			--print(playerObject.name,playerObject.index,shipName,shipX,shipY,shipType)
			local craftInfo = {} -- now, let's put it all into one table
			craftInfo.name = shipName:gsub("%s+", " ") -- one of my players keeps somehow accomplishing putting a newline in each of his ship names so i have to sanitize a little
			craftInfo.type = shipType
			craftInfo.x = shipX
			craftInfo.y = shipY
			craftInfo.ownerIndex = playerObject.index
			craftInfo.ownerName = playerObject.name:gsub("%s+", " ")
			table.insert(fullCraftListing,craftInfo) -- and finally append to the big table we'll print to file later.
		end

		-- now for the player's alliance, if they have one.

		if playerObject.alliance ~= nil then
			--print("player " .. playerObject.name .. " is a member of an alliance!")
			-- this player is a member of an alliance! let's iterate through it as well.

			local allianceObject = playerObject.alliance -- copy out a reference to our alliance so it's easier to look at

			-- check the list of alliances we've already poked at
			if has_value(alreadyIteratedAlliances,allianceObject.index) then
				-- we've already been through this alliance
				--print("skipping re-indexing of alliance " .. allianceObject.name .. "'s (#" .. allianceObject.index .. ") ships")
			else
				-- this one's a new one. let's iterate through it
				print("indexing alliance " .. allianceObject.name .. "'s (#" .. allianceObject.index .. ") ships...")

				-- same verse, same as the first
				local thisAllianceShipListing = { allianceObject:getShipNames() }
				for key, shipName in pairs(thisAllianceShipListing) do
					-- grab the information we need
					local shipX, shipY = allianceObject:getShipPosition(shipName)
					local shipType = allianceObject:getShipType(shipName)

					--print(allianceObject.name,allianceObject.index,shipName,shipX,shipY,shipType)
					local craftInfo = {} -- now, let's put it all into one table
					craftInfo.name = shipName:gsub("%s+", " ")
					craftInfo.type = shipType
					craftInfo.x = shipX
					craftInfo.y = shipY
					craftInfo.ownerIndex = allianceObject.index
					craftInfo.ownerName = allianceObject.name:gsub("%s+", " ")
					table.insert(fullCraftListing,craftInfo) -- and finally append to the big table we'll print to file later.
				end

				-- now, we add this alliance's index to the list of ones we've already looked through
				table.insert(alreadyIteratedAlliances,allianceObject.index) -- append our current index to a
			end
		else
			-- this player's not associated with any alliance - let's move on
			--print("player " .. playerObject.name .. " has no alliance. moving on to next player.")
		end
	end

	print("full ship listing complete! now writing to file.")

	-- write the TSV file's header

	local craftsListingClobber = io.open(fileToWrite,"w+")
	if craftsListingClobber == nil then
		returnValue = commandName .. ": Could not clobber craftslisting."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end
	craftsListingClobber:write("Name",sep,"Type",sep,"Owner",sep,"X",sep,"Y",sep,"Owner Index","\n")
	io.close(craftsListingClobber)

	-- then the contents of the data itself

	local craftsListingAppend = io.open(fileToWrite,"a+")
	if craftsListingAppend == nil then
		returnValue = commandName .. ": Could not open craftslisting for appending."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	for key, craft in pairs(fullCraftListing) do

		local craftTypeName = "None" -- you shouldn't see this

		-- i hate everything about this.
		if craft.type == 1 then 
			craftTypeName = "Ship"
		elseif craft.type == 3 then
			craftTypeName = "Station"
		else
			craftTypeName = "Unknown ("..craft.type..")"
		end


		craftsListingAppend:write(craft.name, sep, craftTypeName, sep, craft.ownerName, sep, craft.x, sep, craft.y, sep, craft.ownerIndex,"\n") -- write out our outgoing line
	end
	io.close(craftsListingAppend) -- close the file handle


	returnValue = commandName .. ": Wrote full list of all player/alliance ships to parseable file."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end