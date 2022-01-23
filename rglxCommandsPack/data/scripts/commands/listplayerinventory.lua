local commandName = "/listPlayerInventory"
local commandDescription = "Writes a full listing of player inventory to the server console. Useful for identifying and removing glitched items."
local commandHelp = "<int: faction/player ID>"

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

	-- Player() returns nil if this is being run from the console, not in-game - let's just fake a "console" player for now until that gets patched.
	if player == nil then
		player = {}
		player.name = "Console"
	end

	if playerId == nil then
		returnValue = commandName .. ": invalid player/alliance ID supplied."
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	local targetPlayer = Player(playerId)

	if targetPlayer == nil then
		returnValue = commandName .. ": could not find this player/alliance!"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	if targetPlayer.isAIFaction == true then
		returnValue = commandName .. ": this is an NPC faction??"
		print( player.name .. " ran " .. returnValue )
		return 1, returnValue, returnValue
	end

	print(targetPlayer.name,"#"..targetPlayer.index,"inventory contents")

	local targetInventory = targetPlayer:getInventory()

	local inventoryContents = targetInventory:getItems()

	for key, value in pairs(inventoryContents) do
		-- key is our inventory index
		local item = value["item"] -- our item itself
		local quantity = value["amount"] -- and the number occupying that slot, if they can stack.

		if item.itemType == 1 or item.itemType == 0 then
			print (key,value["amount"] .. "x",value["item"].name,value["item"].weaponName)
		else
			print (key,value["amount"] .. "x",value["item"].name,value["item"].script)
		end
	end

	returnValue = commandName .. ": Wrote inventory listing for player/alliance ".. targetPlayer.name .." (#".. targetPlayer.index .. ") to server console."
	print( player.name .. " ran " .. returnValue )
	return 0, returnValue, returnValue
end