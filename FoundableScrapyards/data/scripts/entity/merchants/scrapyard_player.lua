package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("utility")
include ("faction")
include ("randomext")
include ("callable")
include ("weapontype")
include ("stringutility")
include ("goods")
include ("reconstructiontoken")
include ("weapontypeutility")
include ("relations")
local TurretIngredients = include("turretingredients")
local SellableInventoryItem = include("sellableinventoryitem")
local Dialog = include("dialogutility")


-- this is practically a direct copy of the base scrapyard.lua script but I've removed its ability to "claim" wreckages in its sector so all it is now is a wastebin for you to chuck ships and guns you hate.
--it's also lighter on your server so you don't have to worry about it breaking things if you have more scrapyards than what the server generated in the galaxy to begin with.
-- rglx


-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ScrapyardPlayer
ScrapyardPlayer = {}

ScrapyardPlayer.interactionThreshold = -30000

-- client
local tabbedWindow = nil
local planDisplayer = nil
local sellButton = nil
local sellWarningLabel = nil
local uiMoneyValue = 0
local visible = false

-- turret tab
local inventory = nil
local scrapButton = nil
local goodsLabels = {}

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function ScrapyardPlayer.interactionPossible(playerIndex, option)
	return CheckFactionInteraction(playerIndex, ScrapyardPlayer.interactionThreshold)
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function ScrapyardPlayer.initialize()

	if onServer() then

		local station = Entity()
		if station.title == "" then
			station.title = "Scrapyard"%_t
		end

	end

	if onClient() and EntityIcon().icon == "" then
		EntityIcon().icon = "data/textures/icons/pixel/scrapyard_thin.png"
		InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
	end
end

function ScrapyardPlayer.initializationFinished()
	-- use the initilizationFinished() function on the client since in initialize() we may not be able to access Sector scripts on the client
	if onClient() then
		local ok, r = Sector():invokeFunction("radiochatter", "addSpecificLines", Entity().id.string,
		{
			"I'd like to see something brand new for once."%_t,
			"Don't like your ship anymore? We'll turn it into scrap and even give you some Credits for it!"%_t,
			"Brand new offer: We now dismantle turrets into parts!"%_t,
			"We don't take any responsibility for any lost limbs while using the turret dismantler."%_t,
		})
	end
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function ScrapyardPlayer.initUI()

	local res = getResolution()
	local size = vec2(700, 650)

	local menu = ScriptUI()
	local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	menu:registerWindow(mainWindow, "Scrapyard"%_t, 10)
	mainWindow.caption = "Scrapyard"%_t
	mainWindow.showCloseButton = 1
	mainWindow.moveable = 1

	-- create a tabbed window inside the main window
	tabbedWindow = mainWindow:createTabbedWindow(Rect(vec2(10, 10), size - 10))

	-- create a "Sell" tab inside the tabbed window
	local sellTab = tabbedWindow:createTab("Sell Ship"%_t, "data/textures/icons/sell-ship.png", "Sell your ship to the scrapyard."%_t)
	size = sellTab.size

	planDisplayer = sellTab:createPlanDisplayer(Rect(0, 0, size.x - 20, size.y - 60))
	planDisplayer.showStats = 0

	sellButton = sellTab:createButton(Rect(0, size.y - 40, 150, size.y), "Sell Ship"%_t, "onSellButtonPressed")
	sellWarningLabel = sellTab:createLabel(vec2(200, size.y - 30), "Warning! You will not get refunds for crews or turrets!"%_t, 15)
	sellWarningLabel.color = ColorRGB(1, 1, 0)

	-- create a tab for dismantling turrets
	local turretTab = tabbedWindow:createTab("Turret Dismantling /*UI Tab title*/"%_t, "data/textures/icons/recycle-turret.png", "Dismantle turrets into goods."%_t)

	local hsplit = UIHorizontalSplitter(Rect(turretTab.size), 10, 0, 0.17)

	local lister = UIVerticalLister(hsplit.top, 10, 0)
	local vmsplit = UIVerticalMultiSplitter(lister:nextRect(30), 10, 0, 2)

	scrapButton = turretTab:createButton(vmsplit.left, "Dismantle"%_t, "onDismantleTurretPressed")
	scrapButton.active = false
	scrapButton.textSize = 14

	local scrapTrashButton = turretTab:createButton(vmsplit.right, "Dismantle Trash"%_t, "onDismantleTrashPressed")
	scrapTrashButton.textSize = 14

	inventory = turretTab:createInventorySelection(hsplit.bottom, 10)
	inventory.onSelectedFunction = "onTurretSelected"
	inventory.onDeselectedFunction = "onTurretDeselected"


	turretTab:createFrame(lister.rect)

	lister:setMargin(10, 10, 10, 10)

	local hlister = UIHorizontalLister(lister.rect, 10, 10)

	for i = 1, 10 do
		local rect = hlister:nextRect(30)
		rect.height = rect.width

		local pic = turretTab:createPicture(rect, "data/textures/icons/rocket.png")
		pic:hide()
		pic.isIcon = true

		local label = turretTab:createLabel(rect.bottomRight - 5, "?", 10)
		label:hide()

		table.insert(goodsLabels, {icon = pic, label = label})
	end

	-- warn box
	local size = vec2(550, 230)
	local warnWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	ScrapyardPlayer.warnWindow = warnWindow
	warnWindow.caption = "Confirm Dismantling"%_t
	warnWindow.showCloseButton = 1
	warnWindow.moveable = 1
	warnWindow.visible = false

	local hsplit = UIHorizontalSplitter(Rect(vec2(), warnWindow.size), 10, 10, 0.5)
	hsplit.bottomSize = 40

	warnWindow:createFrame(hsplit.top)

	local ihsplit = UIHorizontalSplitter(hsplit.top, 10, 10, 0.5)
	ihsplit.topSize = 20

	local label = warnWindow:createLabel(ihsplit.top.lower, "Warning"%_t, 16)
	label.size = ihsplit.top.size
	label.bold = true
	label.color = ColorRGB(0.8, 0.8, 0)
	label:setTopAligned();

	local warnWindowLabel = warnWindow:createLabel(ihsplit.bottom.lower, "Text"%_t, 14)
	ScrapyardPlayer.warnWindowLabel = warnWindowLabel
	warnWindowLabel.size = ihsplit.bottom.size
	warnWindowLabel:setTopAligned();
	warnWindowLabel.wordBreak = true
	warnWindowLabel.fontSize = 14


	local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
	warnWindow:createButton(vsplit.left, "OK"%_t, "onConfirmButtonPress")
	warnWindow:createButton(vsplit.right, "Cancel"%_t, "onCancelButtonPress")
end

function ScrapyardPlayer.onSellButtonPressed()

	ScrapyardPlayer.warnWindowLabel.caption = "This action is irreversible."%_t .."\n\n" ..
	"Your ship will be dismantled and you will be returned to your drone."%_t .."\n\n" ..
	"You will not get refunds for crews or turrets!"%_t

	ScrapyardPlayer.warnWindow:show()
end


-- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
function ScrapyardPlayer.renderUI()

	if tabbedWindow:getActiveTab().name == "Sell Ship"%_t then
		renderPrices(planDisplayer.lower + 20, "Ship Value:"%_t, uiMoneyValue, nil)
	end
end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function ScrapyardPlayer.onShowWindow()
	visible = true

	local ship = Player().craft
	if not ship then return end

	-- get the plan of the player's ship
	local plan = ship:getFullPlanCopy()
	planDisplayer.plan = plan

	if ship.isDrone then
		sellButton.active = false
		sellWarningLabel:hide()
	else
		sellButton.active = true
		sellWarningLabel:show()
	end

	uiMoneyValue = ScrapyardPlayer.getShipValue(plan)

	-- turrets
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)

end

function ScrapyardPlayer.onDismantleTurretPressed()
	local selected = inventory.selected
	if selected then
		invokeServerFunction("dismantleInventoryTurret", selected.index)
	end
end

function ScrapyardPlayer.onDismantleTrashPressed()
	invokeServerFunction("dismantleTrash")
end

function ScrapyardPlayer.onTurretSelected()
	local selected = inventory.selected
	if not selected then return end
	if not selected.item then return end
	if selected.favorite then return end

	scrapButton.active = true

	local _, possible = ScrapyardPlayer.getTurretGoods(selected.item)

	for _, line in pairs(goodsLabels) do
		line.icon:hide()
		line.label:hide()
	end

	table.sort(possible, function(a, b) return a.name < b.name end)

	local i = 1
	for _, good in pairs(possible) do
		local line = goodsLabels[i]; i = i + 1
		line.icon:show()
		line.label:show()

		line.icon.picture = good.icon
		line.icon.tooltip = good:displayName(10)
	end
end

function ScrapyardPlayer.onTurretDeselected()
	scrapButton.active = false

	for _, line in pairs(goodsLabels) do
		line.icon:hide()
		line.label:hide()
	end
end

function ScrapyardPlayer.onTurretDismantled()
	local ship = Player().craft
	if not ship then return end

	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
end

-- this function gets called every time the window is closed on the client
function ScrapyardPlayer.onCloseWindow()
	local station = Entity()
	displayChatMessage("Please, do come again."%_t, station.title, 0)

	visible = false
end


function ScrapyardPlayer.onConfirmButtonPress()
	invokeServerFunction("sellCraft")
	ScrapyardPlayer.warnWindow:hide()
end

function ScrapyardPlayer.onCancelButtonPress()
	ScrapyardPlayer.warnWindow:hide()
end

function ScrapyardPlayer.getUpdateInterval()
	return 1
end

function ScrapyardPlayer.transactionComplete()
	ScriptUI():stopInteraction()
end

function ScrapyardPlayer.sellCraft()

	if not CheckFactionInteraction(callingPlayer, ScrapyardPlayer.interactionThreshold) then return end

	local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.ModifyCrafts, AlliancePrivilege.SpendResources)
	if not buyer then return end

	-- don't allow selling drones, would be an infinite income source
	if ship.isDrone then return end

	player.craftIndex = Uuid()

	-- Create Wreckage
	local position = ship.position
	local plan = ship:getMovePlan();
	local name = ship.name

	-- remove the old craft
	Sector():deleteEntity(ship)

	-- create a wreckage in its place
	local moneyValue = ScrapyardPlayer.getShipValue(plan)

	local wreckageIndex = Sector():createWreckage(plan, position)

	buyer:setShipDestroyed(name, true)
	buyer:removeDestroyedShipInfo(name)

	removeReconstructionTokens(buyer, name)

	buyer:receive(Format("Received %2% Credits for %1% from a scrapyard."%_T, ship.name, createMonetaryString(moneyValue)), moneyValue)

	invokeClientFunction(player, "transactionComplete")
end
callable(ScrapyardPlayer, "sellCraft")

function ScrapyardPlayer.getShipValue(plan)
	local sum = plan:getMoneyValue()
	local resourceValue = {plan:getResourceValue()}

	for i, v in pairs (resourceValue) do
		sum = sum + Material(i - 1).costFactor * v * 10;
	end

	-- players only get money, and not even the full value.
	-- This is to avoid exploiting the scrapyard functionality by buying and then selling ships
	return sum * 0.75
end

function ScrapyardPlayer.dismantleInventoryTurret(inventoryIndex)

	if not CheckFactionInteraction(callingPlayer, ScrapyardPlayer.interactionThreshold) then return end

	local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems, AlliancePrivilege.TakeItems)
	if not buyer then return end

	local inventory = buyer:getInventory()
	local turret = inventory:find(inventoryIndex)
	if not turret or turret.itemType ~= InventoryItemType.Turret then return end

	local goods = ScrapyardPlayer.getTurretGoods(turret)

	local totalSize = 0
	for _, result in pairs(goods) do
		totalSize = totalSize + result.amount + result.good.size
	end

	local cargoBay = CargoBay(ship)
	if not cargoBay or cargoBay.freeSpace < totalSize then
		player:sendChatMessage(Entity(), ChatMessageType.Error, "Not enough cargo space for all dismantled goods!"%_T)
		return
	end

	inventory:take(inventoryIndex)

	for _, result in pairs(goods) do
		cargoBay:addCargo(result.good, result.amount)
	end

	invokeClientFunction(player, "onTurretDismantled")

end
callable(ScrapyardPlayer, "dismantleInventoryTurret")

function ScrapyardPlayer.dismantleTrash()

	if not CheckFactionInteraction(callingPlayer, ScrapyardPlayer.interactionThreshold) then return end

	local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems, AlliancePrivilege.TakeItems)
	if not buyer then return end

	local inventory = buyer:getInventory()

	local items = buyer:getInventory():getItems()

	for inventoryIndex, slotItem in pairs(items) do

		local turret = slotItem.item
		if turret == nil then goto continue end
		if not turret.trash then goto continue end
		if turret.itemType ~= InventoryItemType.Turret then goto continue end

		local stop = false

		for i = 1, slotItem.amount do

			local goods = ScrapyardPlayer.getTurretGoods(turret)

			local totalSize = 0
			for _, result in pairs(goods) do
				totalSize = totalSize + result.amount + result.good.size
			end

			local cargoBay = CargoBay(ship)
			if not cargoBay or cargoBay.freeSpace < totalSize then
				player:sendChatMessage(Entity(), ChatMessageType.Error, "Not enough cargo space for all dismantled goods!"%_T)
				stop = true
				break
			end

			if inventory:take(inventoryIndex) then
				for _, result in pairs(goods) do
					cargoBay:addCargo(result.good, result.amount)
				end
			end
		end

		if stop then break end

		::continue::
	end

	invokeClientFunction(player, "onTurretDismantled")
end
callable(ScrapyardPlayer, "dismantleTrash")

function ScrapyardPlayer.getTurretGoods(turret)
	local item = SellableInventoryItem(turret)
	local value = item.price * 0.1

	local weaponType = WeaponTypes.getTypeOfItem(turret)

	local gainable = table.deepcopy(TurretIngredients[weaponType]) or table.deepcopy(TurretIngredients[WeaponType.ChainGun])
	local usedGoods = {}

	table.insert(gainable, {name = "Scrap Metal"})
	table.insert(gainable, {name = "Servo"})

	for _, ingredient in pairs(gainable) do
		ingredient.good = goods[ingredient.name]:good()
		usedGoods[ingredient.good.name] = ingredient.good
	end

	local possibleGoods
	local result = {}
	result["Servo"] = 1

	for i = 1, (3 + turret.rarity.value) do

		-- remove all ingredients which, by themselves, would already be more expensive than the remaining value of the turret
		for k, ingredient in pairs(gainable) do
			if ingredient.good.price > value then
				gainable[k] = nil
			end
		end

		-- on first iteration, those goods are the ones that are technically possible
		if not possibleGoods then
			possibleGoods = {}

			local added = {}
			for k, ingredient in pairs(gainable) do
				if not added[ingredient.name] then
					table.insert(possibleGoods, usedGoods[ingredient.name])
					added[ingredient.name] = true
				end
			end

			if not added["Servo"] then
				table.insert(possibleGoods, usedGoods["Servo"])
			end
		end

		if tablelength(gainable) > 1 then
			local weights = {}

			for k, ingredient in pairs(gainable) do
				weights[ingredient.name] = (ingredient.amount or 0) + 2
			end
			local name = selectByWeight(random(), weights)

			local maxAmount = math.max(1, math.floor(value / usedGoods[name].price))
			local gained = math.min(maxAmount, 5)

			result[name] = (result[name] or 0) + gained

			value = value - usedGoods[name].price * gained
		else
			for _, ingredient in pairs(gainable) do
				local name = ingredient.name
				local amount = math.max(1, math.floor(value / usedGoods[name].price))

				result[name] = (result[name] or 0) + amount
				break
			end

			break
		end
	end

	for k, amount in pairs(result) do
		result[k] = {name = k, amount = amount, good = usedGoods[k]}
	end

	return result, possibleGoods
end
print("rglx-FoundableScrapyards: player-foundable scrapyard loaded!")