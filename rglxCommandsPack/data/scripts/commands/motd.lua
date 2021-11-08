package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/motd"
commandDescription = "Shows the server's MOTD."
commandHelp = ""

local function lines_from(file) -- https://stackoverflow.com/questions/11201262/
	lines = {}
	for line in io.lines(file) do 
		lines[#lines + 1] = line
	end
	return lines
end

local function stringStartsWith(haystack, needle)
	return haystack:find(needle, 1, true) ~= nil
end

local function readIniFileToTable(filename)
	-- i hate that i have to write an ini parser for things that should just be present in the GameSettings()
	local sectionName = "default"
	local returnedTable = {} -- create main table
	returnedTable[sectionName] = {} -- create sub-table

	local rawServerConfig = lines_from(filename)
	for k,v in pairs(rawServerConfig) do
		if stringStartsWith(v,"[") then
			sectionName = string.match(v,"^%[(.*)%]$")
			returnedTable[sectionName] = {} -- create sub-table
			--print ("new section: " .. sectionName)
		elseif stringStartsWith(v,";") then
			--print ("skipping a comment")
		else
			local directiveName, directiveValue = string.match(v,"^(.*)=(.*)$")
			if directiveName ~= nil and directiveValue ~= nil then
				if tonumber(directiveValue) ~= nil then
					returnedTable[sectionName][directiveName] = tonumber(directiveValue)
				else
					returnedTable[sectionName][directiveName] = directiveValue
				end
			end
		end
	end

	return returnedTable
end

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
	
	local serverConfig = readIniFileToTable(Server().folder .. "/server.ini")
	if serverConfig ~= nil then
		returnValue = serverConfig["Game"]["motd"]
	end

	print( player.name .. " requested galaxy's Message of the Day" )
	return 0, returnValue, returnValue
end