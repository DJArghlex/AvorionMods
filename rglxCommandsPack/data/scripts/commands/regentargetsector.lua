-- command to remotely regenerate another sector.
-- if the sector's occupied by a player, this will not work to prevent sector hangs and subsequent server shutdown.

commandName = "/regenTargetSector"
commandDescription = "Regenerates a sector, without touching player/alliance ships. This will not work with players in the sector!"
commandHelp = "<x y>"

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
	local returnValue = nil
	local player = Player()
	local galaxy = Galaxy()
	local server = Server()
	local x = nil
	local y = nil

	-- prevent clients from running this
	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end

	-- allow only the console, RCON, and administrators to use this command
	if player == nil then
		player = {}
		player.name = "Console"
	elseif not server:hasAdminPrivileges(player) then
		returnValue = commandName .. ": You don't have permission."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	if type(tonumber(args[1])) ~= "number" or type(tonumber(args[2])) ~= "number" then
		-- not numbers
		returnValue = commandName .. ": Please specify sector coordinates as two numbers."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	elseif tonumber(args[1],10) == nil or tonumber(args[2],10) == nil then
		-- numbers aren't whole numbers
		returnValue = commandName .. ": Please specify sector coordinates as two WHOLE numbers."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	elseif tonumber(args[1],10) > 500 or tonumber(args[1],10) < -499 or tonumber(args[2],10) > 500 or tonumber(args[2],10) < -499 then
		-- outside galactic coordinates
		returnValue = commandName .. ": Please specify valid sector coordinates"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	else
		-- they're valid seeming coordinates. let's attempt regeneration
		x = tonumber(args[1])
		y = tonumber(args[2])
	end

	if not x or not y then
		returnValue = commandName .. ": ERROR! something's wrong with your coordinates."
		eprint( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

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

	local specs = SectorSpecifics(x, y, GameSeed())

	local loadRegenerationScript = [[
		function init()
			local sector = Sector()
			if sector:getPlayers() == nil then
				-- nobody present in sector. let's load the script, but only one copy of it.
				Sector():addScriptOnce('rglx_regensector')
			else
				eprint("rglx_cmdsPack_regenOtherSector: players present in targetted sector, aborting!")
			end
		end
	]]

	if specs.generationTemplate then
		-- all checks passed. sector is a valid pre-generated sector of some kind. let's try and load it and generate.
		local sectorLoadedAlready = Galaxy():keepOrGetSector(x, y, 60, loadRegenerationScript)
		if sectorLoadedAlready == true then
			-- sector was loaded already, which means keepOrGetSector() didn't run our code.
			-- let's just run the code since it will make sure nobody's in there.
			local sectorLoadedAtRuncode = runSectorCode(x, y, true, loadRegenerationScript, "init")
			returnValue = commandName .. ": Sector ("..x..":"..y..") is now regenerating. Monitor the console for progress."
			print( player.name .. " ran " .. returnValue )
			return 0, returnValue, returnValue
		else
			-- sector was not loaded initially, which means the regeneration script loader was/will be executed
			returnValue = commandName .. ": Sector ("..x..":"..y..") is loading, please try this command again in a second."
			print( player.name .. " ran " .. returnValue )
			return 0, returnValue, returnValue
		end
	else
		returnValue = commandName .. ": Sector ("..x..":"..y..") has no generation script!"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	returnValue = commandName .. ": Sector ("..x..":"..y..") regeneration complete."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end
