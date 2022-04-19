local commandName = "/listFactionCrafts"
local commandDescription = "Lists a specified player or alliance's crafts' coordinates."
local commandHelp = "<player/alliance ID>"

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

function execute(sender, commandName, ...)
	local args = {...}
	--print(args[1])
	local playerId = tonumber(args[1])
	local returnValue = nil

	local player = Player()
	local server = Server()
	local galaxy = Galaxy()

	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		player = {}
		player.name = "Console"
	end

	-- non numbers aren't faction IDs
	if playerId == nil then
		returnValue = commandName .. ": invalid faction ID specified."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local targetFaction = Faction(playerId)
	-- if the ID was a number but didn't yield a faction
	if targetFaction == nil then
		returnValue = commandName .. ": faction does not exist?"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- ignore NPC factions
	if targetFaction.isAIFaction then
		returnValue = commandName .. ": NPC factions aren't supported by this command."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local stringToReturn = ""

	-- cast to proper type for the faction so we can get at the right methods
	if targetFaction.isAlliance then
		targetFaction = Alliance(targetFaction.index)
		stringToReturn = "Ships and locations of Alliance '" .. targetFaction.name .. "' (#".. targetFaction.index .."):\n"
	elseif targetFaction.isPlayer then
		targetFaction = Player(targetFaction.index)
		stringToReturn = "Ships and locations of Player '" .. targetFaction.name .. "' (#".. targetFaction.index .."):\n"
	end

	local shipNames = { targetFaction:getShipNames() }
	local shipsByLocation = {}

	for _, shipName in ipairs(shipNames) do
		-- for each ship we've found under our target faction, we need to retrieve its location (or if it doesn't exist, show a 'location unknown' text i.e. for a ship that's on a mission)
		local shipX, shipY = targetFaction:getShipPosition(shipName)
		local shipLocation = nil
		if tonumber(shipX) == nil or tonumber(shipY) == nil then
			shipLocation = "[location unknown]"
		else
			shipLocation = "(".. shipX ..":".. shipY ..")"
		end

		-- now, let's add it to the sub-table (or create it if it doesn't exist)
		if shipsByLocation[shipLocation] == nil then
			shipsByLocation[shipLocation] = {shipName}
		else
			table.insert(shipsByLocation[shipLocation],shipName)
		end
	end

	for location, shipList in pairs(shipsByLocation) do
		-- now, we can iterate over each of our locations that has a ship, and write it all out.
		print(location)
		if #shipList > 10 then
			stringToReturn = stringToReturn .. location .. "\t" .. "[" .. #shipList .. " crafts]" .. "\t" .. "list omitted- too long"
		else
			stringToReturn = stringToReturn .. location .. "\t" .. "[" .. #shipList .. " crafts]" .. "\t"
			for _, shipName in ipairs(shipList) do
				stringToReturn = stringToReturn .. shipName .. "  "
			end
		end
		stringToReturn = stringToReturn .. "\n"
	end

	returnValue = commandName .. ": Indexed faction ID #".. playerId .."'s crafts."

	returnValue = returnValue .. "\n" .. stringToReturn

	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end