commandName = "/regenCurrentSector"
commandDescription = "Regenerates this sector, without touching player/alliance ships."
commandHelp = ""

package.path = package.path .. ";data/scripts/?.lua"
local SectorSpecifics = include ("sectorspecifics")

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
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

	if player == nil then
		returnValue = commandName .. ": Can't regenerate sectors without being physically in them."
		eprint( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end


	local sector = Sector()
	local x, y = sector:getCoordinates()

	if not galaxy:sectorExists(x, y) then
		returnValue = commandName .. ": ERROR! ("..x..":"..y..") hasn't been initially generated."
		eprint( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	if galaxy:sectorInRift(x, y) then
		returnValue = commandName .. ": ERROR! ("..x..":"..y..") is in a rift!"
		eprint( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	if not galaxy:sectorLoaded(x, y) then
		returnValue = commandName .. ": ERROR! ("..x..":"..y..") isn't loaded!"
		eprint( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local specs = SectorSpecifics(x, y, GameSeed())

	if specs.generationTemplate then
		sector:removeScript("sector/rglx_regensector.lua")
		sector:addScriptOnce("sector/rglx_regensector.lua")
	else
		returnValue = commandName .. ": Sector ("..x..":"..y..") has no generation script!"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	returnValue = commandName .. ": Sector ("..x..":"..y..") regeneration complete."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end