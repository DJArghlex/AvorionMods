package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/broadcastchatmessage"
commandDescription = "runs Player():sendChatMessage() for all players with your specified arguments."
commandHelp = "[str: sender] [int 0-3: level] [str: message]"

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end


function execute(sender, commandName, ...)
	local args = {...}
	local player = Player()
	local returnValue = "invalid arguments. see documentation on Player():sendChatMessage()"
	
	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		player = {}
		player.name = "Console"
	end

	-- forbid client execution
	if onClient() then
		return 1, "Execution on client forbidden.", "Execution on client forbidden."
	end
	
	-- basic sanity checking
	if args[1] == nil or tonumber(args[2]) == nil or args[3] == nil then
		return 1, returnValue, returnValue
	end

	msglevel = tonumber(args[2])
	if msglevel > 3 or msglevel < 0 then
		return 1, returnValue, returnValue
	end

	local server = Server()
	local onlinePlayers = { server:getOnlinePlayers() } -- table wrapped to make it nice and iteratable

	for key, playerObject in pairs(onlinePlayers) do
		playerObject:sendChatMessage(args[1],msglevel,args[3])
	end
	return 0
end