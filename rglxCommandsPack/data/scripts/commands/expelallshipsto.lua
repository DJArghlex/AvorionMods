package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/expelAllShipsTo"
commandDescription = "Sends all player- and alliance-owned ships to a given sector"
commandHelp = "<x> <y>"

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
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
	local sector = Sector()
	local galaxy = Galaxy()

	local sectorX, sectorY = sector:getCoordinates()

	-- initial variables
	local destination = {}
	destination.x = nil
	destination.y = nil
	local shipsExpelled = 0

	-- forbid non-admin players and the console from running this command
	if player == nil then
		returnValue = commandName .. ": You can't run this from console."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	elseif not server:hasAdminPrivileges(player) then
		returnValue = commandName .. ": You don't have permission."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- require two arguments for our destination
	if args[1] == nil or args[2] == nil then
		returnValue = commandName .. ": Please specify a destination sector."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	destination.x = tonumber(args[1])
	destination.y = tonumber(args[2])

	-- require two numbers for our destination
	if destination.x == nil or destination.y == nil then
		returnValue = commandName .. ": Please specify a destination sector using two numbers."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- require two *whole* numbers for our destination
	if destination.x % 1 ~= 0 and destination.y % 1 ~= 0 then
		returnValue = commandName .. ": Please specify a valid destination sector, with whole-number coordinates."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- make sure the destination coordinates are in the galaxy
	if destination.x >= 500 and destination.x <= -499 and destination.y >= 500 and destination.y <= -499 then
		returnValue = commandName .. ": Please specify a destination sector within the galaxy."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- make sure the destination isn't a rift sector
	if galaxy:sectorInRift(destination.x,destination.y) then
		returnValue = commandName .. ": Please specify a non-rift destination sector."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	-- so that's all the sanity checks we need. let's start moving player and alliance ships
	for _, ship in pairs({sector:getEntitiesByType(EntityType.Ship)}) do
		if ship.allianceOwned or ship.playerOwned then
			-- only transfer player/alliance ships
			sector:transferEntity(ship,destination.x,destination.y,SectorChangeType.Jump)
			shipsExpelled = shipsExpelled + 1
		end
	end

	returnValue = commandName .. ": successfully expelled " .. shipsExpelled .. " ships from (" .. sectorX .. ":" .. sectorY ..") to (" .. destination.x .. ":" .. destination.y .. ")"
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end