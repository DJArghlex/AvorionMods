package.path = package.path .. ";data/scripts/?.lua"

local SectorSpecifics = include ("sectorspecifics")

commandName = "/mapWholeGalaxyToFile"
commandDescription = "Maps the entire galaxy to a tab-separated values file in your galaxy's root."
commandHelp = ""

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end

function execute(sender, commandName, ...)
	local args = ...
	local player = Player()
	local returnValue = nil

	if onClient() then
		returnValue = "Execution on client forbidden."
		return 1, returnValue, returnValue
	end

	if player == nil then
		player = {}
		player.name = "Console"
	end

	-- tsv header
	local tableheader = {
		"x",
		"y",
		"name",
		"generationTemplate",
		"faction",
		"factionIndex",
		"centralArea",
		"gates",
		"ancientGates",
		"regular",
		"offgrid",
		"blocked",
		"sectorSeed",
		"generationSeed"
	}

	-- delete existing file and write anew
	local server = Server()
	local logFile = server.folder .. "/sectorspecifics.tsv"
	local logFileHandle = io.open(logFile,"w")
	if logFileHandle ~= nil then
		logFileHandle:write(table.concat(tableheader,"\t") .. "\n")
		io.close(logFileHandle)
	else
		returnValue = commandName .. ": ERROR! couldn't delete and reopen file!"
		eprint( player.name .. " ran " .. returnValue )
		return 0, returnValue, returnValue
	end


	local logFileHandleAppend = io.open(logFile,"a")
	if logFileHandleAppend == nil then
		returnValue = commandName .. ": ERROR! couldn't open file!"
		eprint( player.name .. " ran " .. returnValue )
		return 0, returnValue, returnValue
	end

	local galaxy = Galaxy()

	local counter = 0

	minX = -499
	maxX = 500
	minY = -499
	maxY = 500
	print("rglx_CmdsPack_mapwholegalaxytofile: BEGINNING SCANNING OF THE ENTIRE GALAXY. This will take some time!")

	for x=minX,maxX,1 do	
		for y=minY,maxY,1 do

			-- only show us existing sectors in the database.
			if galaxy:sectorExists(x,y) == true then

				local specifics = SectorSpecifics(x, y, GameSeed())


				-- if we have a gate template for the sector, only save the fact that it has gates, not its entire script object.
				if specifics.gates then
					specifics.gates = true
				else
					specifics.gate = false
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
					specifics.generationTemplate = "empty"
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
					specifics.faction = "nil"
				end


				local orderedSectorInformationTable = 
					specifics.coordinates.x
					.. "\t" ..
					specifics.coordinates.y
					.. "\t" ..
					specifics.name 
					.. "\t" ..
					specifics.generationTemplate
					.. "\t" ..
					specifics.faction
					.. "\t" ..
					specifics.factionIndex
					.. "\t" ..
					tostring(specifics.centralArea)
					.. "\t" ..
					tostring(specifics.gates)
					.. "\t" ..
					tostring(specifics.ancientGates)
					.. "\t" ..
					tostring(specifics.regular)
					.. "\t" ..
					tostring(specifics.offgrid)
					.. "\t" ..
					tostring(specifics.blocked)
					--.. "\t" ..
					--tostring(specifics.sectorSeed)
					--.. "\t" ..
					--tostring(specifics.generationSeed)

				-- and finally, write it out.
				if specifics.generationTemplate ~= "empty" then
					logFileHandleAppend:write(orderedSectorInformationTable .. "\n")
				end

			end

			-- and give some indication of our progress.
			counter = counter + 1
			if counter % 50 == 0 then
				print("rglx_CmdsPack_mapwholegalaxytofile: scanned "..counter.. " sectors...")
			end

		end
	end

	io.close(logFileHandleAppend)

	print("rglx_CmdsPack_mapwholegalaxytofile: Scan complete. Results in sectorspecifics.tsv in your galaxy's root.")

	returnValue = commandName .. ": wrote entire galaxy's sectorspecifics out to file."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end