-- rglx's turret replicator for turret factories.
-- replicate turrets in exchange for resources

package.path = package.path .. ";data/scripts/lib/?.lua"
include ("utility")
include ("player")
include ("faction")
include ("defaultscripts")
include ("randomext")
include ("stationextensions")
include ("galaxy")
include ("randomext")
include ("faction")
include ("player")
include ("stringutility")
include ("callable")
local SellableInventoryItem = include ("sellableinventoryitem")
local Dialog = include("dialogutility")

-- dont remove this next line. used by the game's engine.
-- namespace TurretReplicator

TurretReplicator = {}
TurretReplicator.interactionThreshold = 30000
local replicatorDebug = false -- change to false to suppress extraneous output
local inventory = nil
local replicateButton = nil

if replicatorDebug then
	local x, y = Sector():getCoordinates()
	local turretFactoryLocation = "("..x..":"..y..")"
	local turretFactoryTitle = Entity().title
	local turretFactoryName = Entity().name
end

-- you can override this in a mod on your server (and clients) just make sure the arguments do not change. 
function TurretReplicator.calculateReplicationResources(slotCount,standardPrice,materialIndex,quantity)
	local replicationTax = 1.3
	local baseReplicationCost = 10000 -- base replication fee in credits
	local slotReplicationMultiplier = 5000 -- slot replication cost in credits

	local baseFee = ( baseReplicationCost + slotCount * slotReplicationMultiplier ) -- base fee for the turret itself
	local basePrice = standardPrice * replicationTax -- price of the turret times the replication tax

	local eachPrice = baseFee + basePrice

	local eachPriceInResources = math.ceil( eachPrice / ( 10 * Material(materialIndex).costFactor ) ) -- convert to resource cost

	TurretReplicator.printLog("DEBUG","calculateReplicationResources(): calculated a turret cost")
	return quantity * eachPriceInResources -- and finally, the quantity.
end



function TurretReplicator.printLog(level,message)
	if level == "DEBUG" and replicatorDebug == false then
		return -- don't print if it's a debug message & if those are disabled
	end
	print("[rglx_turretreplicator.lua " .. level .. "] " .. message)
end

function TurretReplicator.initialize()
	TurretReplicator.printLog("DEBUG","initialize(): initializing!")
	return
end


function TurretReplicator.interactionPossible(playerIndex, option)
	return CheckFactionInteraction(playerIndex, TurretReplicator.interactionThreshold)
end


function TurretReplicator.initializationFinished()
	-- add some more flavor text
	if onClient() then
		local ok, r = Sector():invokeFunction("radiochatter", "addSpecificLines", Entity().id.string,
		{
			"New service: Turret replication! Your turrets, just more of them!",
			"RGLX-CORP Turret Replicators and Arms Dealing: More guns, more fun.",
			"Need another turret *just* like that one you put on your other ship? We can fix that. Talk to our replicator AI today.",
		})
	end
	TurretReplicator.printLog("DEBUG","initializationFinished(): initialization completed.")
end

function TurretReplicator.getTechLevel()
	-- returns sector current tech level. also adds support for the tech level 51+ blueprinting mod.
	local currentCoords = {}
	currentCoords.x,currentCoords.y = Sector():getCoordinates()
	local currentTechLevel = Balancing_GetTechLevel(currentCoords.x, currentCoords.y)
	if currentTechLevel > 49 then
		if rglx_TL51BPing then
			currentTechLevel = 52
		else
			currentTechLevel = 50
		end
	end
	return currentTechLevel
end


function TurretReplicator.initUI()
	local res = getResolution()
	local size = vec2(800, 600)

	local menu = ScriptUI()
	local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	menu:registerWindow(mainWindow, "Replicate Turrets")
	mainWindow.caption = "Turret Replicator"
	mainWindow.showCloseButton = 1
	mainWindow.moveable = 1

	local vsplit = UIHorizontalSplitter(Rect(mainWindow.size), 10, 10, 0.17)
	inventory = mainWindow:createInventorySelection(vsplit.bottom, 10)

	inventory.onSelectedFunction = "replicatorTargetSelected"
	inventory.onDeselectedFunction = "replicatorTargetUnselected"

	local lister = UIVerticalLister(vsplit.top, 10, 5)
	replicateButton = mainWindow:createButton(Rect(), "Replicate!", "replicatorActivated")
	lister:placeElementTop(replicateButton)
	replicateButton.active = false
	replicateButton.width = 600

	-- text label for quantity selector
	replicateQtyBoxLabel = mainWindow:createTextField(Rect(20, 0, size.x, 50),"init label")
	lister:placeElementTop(replicateQtyBoxLabel) -- moves the text label to the top part of the lister
	replicateQtyBoxLabel.text = "Quantity to replicate:"
	replicateQtyBoxLabel.fontSize = 15
	replicateQtyBoxLabel:show()

	-- the way this game handles text boxes is WEIRD so let's make it make sense to you.
	-- basically you have to specify the upper left and lower right exact pixel coordiantes inside the Rect() when you initialize it
	tmpTextBoxWidth = 80
	tmpTextBoxHeight = 25
	tmpTextBoxXoffset = 210
	tmpTextBoxYoffset = 67
	replicateQtyBox = mainWindow:createTextBox(Rect(tmpTextBoxXoffset,tmpTextBoxYoffset,tmpTextBoxWidth+tmpTextBoxXoffset,tmpTextBoxHeight+tmpTextBoxYoffset),"")
	replicateQtyBox.allowedCharacters = "0123456789" -- only allow numbers, and whole numbers at that, to be here.
	replicateQtyBox.onTextChangedFunction = "replicatorTargetSelected"
	replicateQtyBox.text = "1" -- default is 1 :)
	-- replicateQtyBox.fontSize = 20 -- doesn't work :(

	mainWindow:createFrame(lister.rect)

	lister:setMargin(10, 10, 10, 10)
	TurretReplicator.printLog("DEBUG","initUI(): UI initialized")
end


function TurretReplicator.onShowWindow()
	local ship = Player().craft
	if not ship then return end
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
	TurretReplicator.printLog("DEBUG","onShowWindow(): window shown")
end


function TurretReplicator.renderUI()
	--TurretReplicator.printLog("DEBUG","renderUI(): UI rendered")
	-- don't enable this
	return
end


function TurretReplicator.refreshUI()
	local ship = Player().craft
	if not ship then return end
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
	TurretReplicator.printLog("DEBUG","refreshUI(): UI refreshed")
	return
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

function TurretReplicator.replicationComplete()
	replicateButton.active = false
	replicateButton.caption = "Done! Enjoy your new turrets!"
	replicateQtyBox.text = "1"
	TurretReplicator.printLog("DEBUG","replicationComplete(): server reports replication complete.")
	local ship = Player().craft
	if not ship then return end
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
	return
end


function TurretReplicator.replicatorActivated()
	replicateButton.active = false
	replicateButton.caption = "Replicating... This should be instantaneous..."
	TurretReplicator.printLog("DEBUG","replicatorActivated(): activated!")
	local selected = inventory.selected
	if selected then
		invokeServerFunction("replicateTurretIntoInventory", selected.index, replicateQtyBox.text)
		TurretReplicator.printLog("DEBUG","replicatorActivated(): invoked server function!")
	else
		replicateButton.caption = "You didn't select a turret."
		replicateButton.active = true
		TurretReplicator.printLog("ERROR","replicatorActivated(): oops, didnt select a turret.")
		return
	end
end


function TurretReplicator.replicateTurretIntoInventory(inventoryIndex,quantityToReplicate)
	if onServer() then -- only run this on the server
		-- relations check
		TurretReplicator.printLog("DEBUG","replicateTurretIntoInventory(): invoked. beginning checks...")
		callingPlayerObj = Player(callingPlayer)
		if not CheckFactionInteraction(callingPlayer, TurretReplicator.interactionThreshold) then
			callingPlayerObj:sendChatMessage("Turret Replicator",1,"You're not friendly enough with this faction.")
			TurretReplicator.printLog("ERROR","replicateTurretIntoInventory(): replication failed, interacting faction failed friendliness check")
			return
		end

		-- buyer permissions/sanity check
		local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.AddItems, AlliancePrivilege.SpendResources, AlliancePrivilege.TakeResources)
		if not buyer then
			callingPlayerObj:sendChatMessage("Turret Replicator",1,"You don't have permission to use resources and items from your alliance vault.")
			TurretReplicator.printLog("ERROR","replicateTurretIntoInventory(): replication failed, player doesn't have permission from alliance")
			return
		end

		-- sanity check for wether the turret exists and is a turret
		local inventory = buyer:getInventory()
		local indexedTurret = inventory:find(inventoryIndex)
		if not indexedTurret or indexedTurret.itemType ~= InventoryItemType.Turret then
			callingPlayerObj:sendChatMessage("Turret Replicator",1,"You can't replicate this item.")
			TurretReplicator.printLog("ERROR","replicateTurretIntoInventory(): replication failed, item is not a turret")
			return
		end

		-- can't replicate ancient turrets
		if indexedTurret.ancient then
			callingPlayerObj:sendChatMessage("Turret Replicator",1,"This is an Ancient item. You can't replicate it.")
			return
		end

		-- check if the player's docked/close enough
		local errors = {}
		errors[EntityType.Station] = "You must be docked to the station to replicate turrets."
		errors[EntityType.Ship] = "You must be closer to the ship to replicate turrets."
		if not CheckPlayerDocked(player, station, errors) then
			return
		end

		-- check if the tech level is high enough here
		if TurretReplicator.getTechLevel() < indexedTurret.averageTech then
			callingPlayerObj:sendChatMessage("Turret Replicator",1,"Tech level here (TL"..TurretReplicator.getTechLevel()..") isn't high enough.")
			return
		end

		-- check that we actually got the right quantity argument or if we got one at all.
		-- this'll only be nil if someone is using an outdated version on the client side, so let's just draw some assumptions to protect the server.
		if quantityToReplicate == nil then
			quantityToReplicate = 1 -- assume 1
		end
		if tonumber(quantityToReplicate) < 1 then
			quantityToReplicate = 1
		end
	
		local resourceType = Material(0) -- this gets overwritten
		local resourceQuantity = 42424242 -- also gets overwritten

		-- stored as ints and strings here
		local turretMaterial = indexedTurret.material.value
		local turretSlotcount = indexedTurret.slots
		local turretRarity = indexedTurret.rarity.value
		local turretPrice = SellableInventoryItem(indexedTurret).price
		local turretWeaponname = indexedTurret.weaponName
		local turretFinalQuantity = inventory:amount(inventoryIndex)+quantityToReplicate


		resourceType = Material(turretMaterial) -- then converted back here
		resourceQuantity = TurretReplicator.calculateReplicationResources(turretSlotcount,turretPrice,turretMaterial,quantityToReplicate) -- but not here.

		TurretReplicator.printLog("DEBUG","replicateTurretIntoInventory(): turret information: Type:" .. turretWeaponname .. " Slots:" .. turretSlotcount .. " Mtl:" .. turretMaterial .. " Rarity:" .. turretRarity .. " FinalQ:" .. turretFinalQuantity .. " CostMtl:" .. resourceType.name .. " CostQ:" .. resourceQuantity)
		invokeClientFunction(Player(callingPlayer),"printLog","DEBUG","invoked replicateTurretIntoInventory() on server: server received turret information: Type:" .. turretWeaponname .. " Slots:" .. turretSlotcount .. " Mtl:" .. turretMaterial .. " Rarity:" .. turretRarity .. " FinalQ:" .. turretFinalQuantity .. " CostMtl:" .. resourceType.name .. " CostQ:" .. resourceQuantity)

		-- check if they can afford it
		if not buyer:canPayResource(resourceType,resourceQuantity) then
			callingPlayerObj:sendChatMessage("Turret Replicator",1,"You can't afford to replicate this. Cost: " .. resourceQuantity .. " " ..  resourceType.name )
			TurretReplicator.printLog("ERROR","replicateTurretIntoInventory(): interacting faction cant afford, Cost: " .. resourceQuantity .. " " ..  resourceType.name )
			return
		end
	
		-- <homer> awww! avorion?? i cant eat this!
		-- <homer's brain> resources can be exchanged for services and turrets
		-- <homer> ohhhh. woohoo!
		local receiptString = Format(buyer.name .. " paid ".. resourceQuantity .." ".. resourceType.name .." to replicate a " .. Rarity(indexedTurret.rarity).name .. " ".. Material(turretMaterial).name .." " .. turretSlotcount .."-slot " .. turretWeaponname .. " Turret")
		buyer:payResource(receiptString,indexedTurret.material,resourceQuantity)
		inventory:setAmount(inventoryIndex,turretFinalQuantity)

		-- refresh the client's window via onShowWindow()
		invokeClientFunction(player, "replicationComplete")
		callingPlayerObj:sendChatMessage("Turret Replicator",3,"Replication Complete.")
	else
		TurretReplicator.printLog("ERROR","replicateTurretIntoInventory(): execution attempt on client? this should not happen.")
	end
end
-- makes callable from clients to be run on the server
callable(TurretReplicator, "replicateTurretIntoInventory")

function TurretReplicator.replicatorTargetSelected()

	-- error checking

	if replicateQtyBox.text == nil then -- client removed all numbers from text box
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. No quantity entered."
		return
	end

	if tonumber(replicateQtyBox.text) < 1 then -- number is less than 1 (aka zero or a negative number)
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. Invalid quantity."
		return
	end

	local selected = inventory.selected
	if not selected then
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. Nothing selected."
		return
	end
	if not selected.item then
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. Not an item."
		return
	end

	-- turret's not an ancient turret
	if selected.item.ancient then
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. Ancient item."
		return
	end

	-- check if the tech level's high enough round these parts
	if TurretReplicator.getTechLevel() < selected.item.averageTech then
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. Tech level not high enough (TL"..TurretReplicator.getTechLevel().." here)"
		return
	end

	-- we're not docked.
	local errors = {}
	errors[EntityType.Station] = nil
	errors[EntityType.Ship] = nil
	if not CheckPlayerDocked(Player(), Entity(),errors) then
		replicateButton.active = false
		replicateButton.caption = "Can't replicate. Not docked."
		return
	end

	local resourceType = Material(0) -- this will be overwritten
	local resourceQuantity = 42424242 --  this will be overwritten

	itemPrice = SellableInventoryItem(selected.item).price
	resourceType = Material(selected.item.material.value)
	resourceQuantity = TurretReplicator.calculateReplicationResources(selected.item.slots,itemPrice,selected.item.material.value,replicateQtyBox.text)

	replicateButton.active = true
	replicateButton.caption="Replicate! (".. comma_value(resourceQuantity) .. " " .. resourceType.name .. ")"
	TurretReplicator.printLog("DEBUG","replicatorTargetSelected(): selected target, "..replicateQtyBox.text.."x ".. selected.item.slots .."-slot " .. selected.item.rarity.value .. "-rare, cost: " .. resourceQuantity .. " " .. resourceType.name)

end


function TurretReplicator.replicatorTargetUnselected()
	replicateButton.active = false
	replicateButton.caption="Replicate! (select a turret)"
	TurretReplicator.printLog("DEBUG","replicatorTargetUnselected(): unselected")
end