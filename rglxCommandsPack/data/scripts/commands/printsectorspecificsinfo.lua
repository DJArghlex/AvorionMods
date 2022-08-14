package.path = package.path .. ";data/scripts/?.lua"

local SectorSpecifics = include ("sectorspecifics")

commandName = "/printSectorSpecificsInfo"
commandDescription = "Prints the default SectorSpecifics() for the current sector, or one you specify."
commandHelp = "[x y]"

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

-- http://lua-users.org/lists/lua-l/2008-11/msg00102.html
-- yes, i'm this lazy.
function isint(n)
	return n==math.floor(n)
end

function execute(sender, commandName, ...)
	local args = {...}
	local player = Player()
	local returnValue = nil
	local galaxy = Galaxy()

	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end

	if #args ~= 2 and #args ~= 0 then
		returnValue = commandName .. ": Wrong number of arguments for sector coordinates."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local x, y = nil, nil


	if #args == 2 then
		args[1] = tonumber(args[1])
		args[2] = tonumber(args[2])

		-- reject non-numbers
		if args[1] == nil and args[2] == nil then
			returnValue = commandName .. ": Given coordinates aren't numbers."
			print( player.name .. " ran " .. returnValue )
			return 1, returnValue, returnValue
		end


		-- reject whole numbers
		if isint(args[1]) == false and isint(args[2]) == false then
			returnValue = commandName .. ": Given coordinates aren't whole numbers."
			print( player.name .. " ran " .. returnValue )
			return 1, returnValue, returnValue
		end

		if -- reject coordinates outside the galaxy
			args[1] < 500 or
			args[1] > -499 or
			args[2] < 500 or
			args[2] > -499
		then
			x, y = args[1], args[2]
		else
			returnValue = commandName .. ": Given coordinates are outside the galactic bounds."
			print( player.name .. " ran " .. returnValue )
			return 1, returnValue, returnValue
		end
	elseif #args == 0 then
		if player == nil then
			returnValue = commandName .. ": Specify coordinates or run from in-game."
			print( player.name .. " ran " .. returnValue )
			return 1, returnValue, returnValue
		else
			x, y = player:getSectorCoordinates()
		end
	end
	local specifics = SectorSpecifics(x, y, GameSeed())


	-- if we have a gate template for the sector, only save the fact that it has gates, not its entire script object.
	if specifics.gates then
		specifics.gates = true
	else
		specifics.gates = false
	end

	-- if we have an ancient gate template, only save the fact that it has ancient gates, not its entire script object.
	if specifics.ancientGates then
		specifics.ancientGates = true
	else
		specifics.ancientGates = false
	end

	-- if we have a generation template, just save its path instead of the entire script object.
	if specifics.generationTemplate then
		specifics.generationTemplate = specifics.generationTemplate.path
	else
		specifics.generationTemplate = "empty!"
	end

	specifics.passageMap = nil
	specifics.templates = nil
	specifics.factionsMap = nil

	-- add a new value for the faction itself
	if not specifics.factionIndex then
		specifics.factionIndex = -1
	end
	specifics.faction = Faction(specifics.factionIndex)
	if specifics.faction then
		specifics.faction = specifics.faction.name
	else
		specifics.faction = "nobody!"
	end

	-- add some information from Galaxy() object
	specifics.sectorExists = galaxy:sectorExists(x, y)
	specifics.sectorInRift = galaxy:sectorInRift(x, y)


	outboundString = "rglx_CmdsPack_printSectorSpecificsInfo: SectorSpecifics() & other info for ".. specifics.name .. ":\n"
	for key,value in pairs(specifics) do
		if key == "coordinates" then
			outboundString = outboundString .. "\t" .. key.. ":\t(" .. value.x .. ":" .. value.y .. ")\n"
		else
			outboundString = outboundString .. "\t" .. key.. ":\t" .. tostring(value) .. "\n"
		end
	end
	outboundString = outboundString .. "\n"

	print(outboundString)

	returnValue = commandName .. ": wrote ("..x..":"..y..")'s SectorSpecifics() information to console."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end