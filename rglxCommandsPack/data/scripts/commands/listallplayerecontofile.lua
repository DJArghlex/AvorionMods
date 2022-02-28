local commandName = "/listAllPlayerEconToFile"
local commandDescription = "Lists all player and alliance economical and playtime stats to a file in the server's root folder."
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

-- from http://lua-users.org/wiki/FormattingNumbers, by a sam_lie there
function comma_value(amount)
  local formatted = amount
  while true do  
	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
	if (k==0) then
	  break
	end
  end
  return formatted
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
	local fileToWrite = server.folder .. "/econlisting.tsv"

	local alreadyIteratedAlliances = {}
	local fullEconomyListing = {}

	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		player = {}
		player.name = "Console"
	end

	print(" *** *** *** ALERT! *** *** *** Attempting to index ALL player & alliance resource/credit vaults in the entire galaxy - this may take some time. If your players move their resources and credits around or build/deconstruct ships between now and the time the server saves and shuts down, the information won't be accurate, so do NOT run this with players connected, and shut the server down when it's finished!")

	print ("attempting to fetch a full list of all players who have connected to the galaxy... this can take a little while.")

	-- this one might be the thing that takes the longest, as it actually retrieves player objects for each player, instead of just handing me a big list of indices to wrap Player() around myself - and some servers (looking at you, tree cafe #1) have had more than three thousand players since their last wipe - so this could cause a significant amount of lag or outright kill a server if it takes too long.

	local fullPlayerListing = { server:getPlayers() } -- retrieves all players that have ever been on the server

	print ("player indexing complete - beginning econ stats indexing")

	for key, playerObject in pairs(fullPlayerListing) do

		print("indexing alliance " .. playerObject.name .. "'s (#" .. playerObject.index .. ") econ stats...")

		-- create an object to add information to.

		local playerEconInfo = {}

		-- retrieve the basic stats
		playerEconInfo.name = playerObject.name
		playerEconInfo.index = playerObject.index
		playerEconInfo.factionType = "Player"
		playerEconInfo.uuid = playerObject.id.id
		playerEconInfo.playtime = playerObject.playtime
		playerEconInfo.credits = playerObject.money
		playerEconInfo.iron, playerEconInfo.titanium, playerEconInfo.naonite, playerEconInfo.trinium, playerEconInfo.xanion, playerEconInfo.ogonite, playerEconInfo.avorion = playerObject:getResources()

		if playerObject.alliance ~= nil then
			playerEconInfo.allianceId = playerObject.alliance.index
		else
			playerEconInfo.allianceId = -1
		end

		table.insert(fullEconomyListing,playerEconInfo) -- and finally append to the big table we'll print to file later.


		-- now for the player's alliance, if they have one.

		if playerObject.alliance ~= nil then
			print("player " .. playerObject.name .. " is a member of an alliance!")
			-- this player is a member of an alliance! let's iterate through it as well.

			local allianceObject = playerObject.alliance -- copy out a reference to our alliance so it's easier to look at

			-- check the list of alliances we've already poked at
			if has_value(alreadyIteratedAlliances,allianceObject.index) then
				-- we've already been through this alliance
				print("skipping re-indexing of alliance " .. allianceObject.name .. "'s (#" .. allianceObject.index .. ") econ stats")
			else
				print("indexing alliance " .. allianceObject.name .. "'s (#" .. allianceObject.index .. ") econ stats...")

				allianceEconInfo = {}

				allianceLeader = Player(allianceObject.leader)

				-- retrieve the basic stats
				allianceEconInfo.name = allianceObject.name
				allianceEconInfo.index = allianceObject.index
				allianceEconInfo.factionType = "Alliance"
				allianceEconInfo.uuid = -1
				allianceEconInfo.allianceId = allianceLeader.index
				allianceEconInfo.playtime = -1
				allianceEconInfo.credits = allianceObject.money
				allianceEconInfo.iron, allianceEconInfo.titanium, allianceEconInfo.naonite, allianceEconInfo.trinium, allianceEconInfo.xanion, allianceEconInfo.ogonite, allianceEconInfo.avorion = allianceObject:getResources()
				
				table.insert(fullEconomyListing,allianceEconInfo) -- and finally append to the big table we'll print to file later.


				table.insert(alreadyIteratedAlliances,allianceObject.index) -- mark this alliance as already iterated through.

			end
		else
			-- this player's not associated with any alliance - let's move on
			print("player " .. playerObject.name .. " has no alliance. moving on to next player.")
		end
	end

	print("full ship listing complete! now writing to file.")

	-- write the TSV file's header

	local econListingClobber = io.open(fileToWrite,"w+")
	if econListingClobber == nil then
		returnValue = commandName .. ": Could not clobber econ stats."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end
	econListingClobber:write("factionType",sep,"name",sep,"index",sep,"steamID",sep,"memberOfAlliance or allianceLeader",sep,"playtimeSeconds",sep,"credits",sep,"iron",sep,"titanium",sep,"naonite",sep,"trinium",sep,"xanion",sep,"ogonite",sep,"avorion","\n")
	io.close(econListingClobber)

	-- then the contents of the data itself

	local econListingAppend = io.open(fileToWrite,"a+")
	if econListingAppend == nil then
		returnValue = commandName .. ": Could not open econ stats for appending."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	for key, entry in pairs(fullEconomyListing) do

		writeOutList = {
			entry.factionType,
			entry.name,
			entry.index,
			entry.uuid,
			entry.allianceId,
			comma_value(entry.playtime),
			comma_value(entry.credits),
			comma_value(entry.iron),
			comma_value(entry.titanium),
			comma_value(entry.naonite),
			comma_value(entry.trinium),
			comma_value(entry.xanion),
			comma_value(entry.ogonite),
			comma_value(entry.avorion),
		}

		econListingAppend:write(table.concat(writeOutList,sep),"\n")
		--print(table.unpack(writeOutList))
	end
	io.close(econListingAppend) -- close the file handle


	returnValue = commandName .. ": Wrote full list of all player/alliance econ and playtime stats to parseable file."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end