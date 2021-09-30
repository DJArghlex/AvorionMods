-- namespace Scrapyard

-- override this with a mod
allowWreckageYardForPlayers = false

function Scrapyard.allowWreckageYard()
	if allowWreckageYardForPlayers == false then
		-- players not allowed, but we have to check which one THIS scrapyard belongs to.
		faction = Faction()

		if faction.isAIFaction then
			return true
		else
			return false
		end
	else
		-- players are allowed to have wreckage yards so just return true
		return true
	end
end

-- overwrites stock function
function Scrapyard.initialize()

	if onServer() then
		if allowWreckageYardForPlayers == true then
			local sector = Sector()
			sector:registerCallback("onHullHit", "onHullHit")
			sector:registerCallback("onEntityCreated", "onEntityCreated")
			sector:registerCallback("onDestroyed", "onEntityDestroyed")
			sector:registerCallback("onEntityDocked", "onEntityDocked")
			sector:registerCallback("onEntityUndocked", "onEntityUndocked")
			sector:registerCallback("onEntityJump", "onEntityJump")
		end
		local station = Entity()
		if station.title == "" then
			station.title = "Scrapyard"%_t
		end

	end

	if onClient() and EntityIcon().icon == "" then
		if Scrapyard.allowWreckageYard() == true then
			EntityIcon().icon = "data/textures/icons/pixel/scrapyard_fat.png"
		else
			EntityIcon().icon = "data/textures/icons/pixel/scrapyard_thin.png"
		end
		InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
	end
end


function Scrapyard.initializationFinished()
    -- use the initilizationFinished() function on the client since in initialize() we may not be able to access Sector scripts on the client
    if onClient() then
    	if Scrapyard.allowWreckageYard() == true then
	        local ok, r = Sector():invokeFunction("radiochatter", "addSpecificLines", Entity().id.string,
	        {
	            "Get a salvaging license now and try your luck with the wreckages!"%_t,
	            "Easy salvage, easy profit! Salvaging licenses for sale!"%_t,
	            "I'd like to see something brand new for once."%_t,
	            "Don't like your ship anymore? We'll turn it into scrap and even give you some Credits for it!"%_t,
	            "Brand new offer: We now dismantle turrets into parts!"%_t,
	            "We don't take any responsibility for any lost limbs while using the turret dismantler."%_t,
	        })
	    else
	        local ok, r = Sector():invokeFunction("radiochatter", "addSpecificLines", Entity().id.string,
	        {
	            "I'd like to see something brand new for once."%_t,
	            "Don't like your ship anymore? We'll turn it into scrap and even give you some Credits for it!"%_t,
	            "Brand new offer: We now dismantle turrets into parts!"%_t,
	            "We don't take any responsibility for any lost limbs while using the turret dismantler."%_t,
	        })
	    end
    end
end

function Scrapyard.initUI()

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



    local fontSize = 18

    if Scrapyard.allowWreckageYard() == true then

	    -- create a second tab
	    local salvageTab = tabbedWindow:createTab("Salvaging /*UI Tab title*/"%_t, "data/textures/icons/recycle-arrows.png", "Buy a salvaging license."%_t)
	    size = salvageTab.size -- not really required, all tabs have the same size

	    local textField = salvageTab:createTextField(Rect(0, 0, size.x, 50), "Buy a temporary salvaging license of maximum 60 minutes here. This license makes it legal to damage or mine wreckages in this sector."%_t)
	    textField.padding = 7

	    salvageTab:createButton(Rect(size.x - 210, 80, 200 + size.x - 210, 40 + 80), "Buy License"%_t, "onBuyLicenseButton1Pressed")
	    salvageTab:createButton(Rect(size.x - 210, 130, 200 + size.x - 210, 40 + 130), "Buy License"%_t, "onBuyLicenseButton2Pressed")
	    salvageTab:createButton(Rect(size.x - 210, 180, 200 + size.x - 210, 40 + 180), "Buy License"%_t, "onBuyLicenseButton3Pressed")
	    salvageTab:createButton(Rect(size.x - 210, 230, 200 + size.x - 210, 40 + 230), "Buy License"%_t, "onBuyLicenseButton4Pressed")

	    salvageTab:createLabel(vec2(15, 85), "5", fontSize)
	    salvageTab:createLabel(vec2(15, 135), "15", fontSize)
	    salvageTab:createLabel(vec2(15, 185), "30", fontSize)
	    salvageTab:createLabel(vec2(15, 235), "60", fontSize)

	    salvageTab:createLabel(vec2(60, 85), "Minutes"%_t, fontSize)
	    salvageTab:createLabel(vec2(60, 135), "Minutes"%_t, fontSize)
	    salvageTab:createLabel(vec2(60, 185), "Minutes"%_t, fontSize)
	    salvageTab:createLabel(vec2(60, 235), "Minutes"%_t, fontSize)

	    priceLabel1 = salvageTab:createLabel(vec2(200, 85),  "", fontSize)
	    priceLabel2 = salvageTab:createLabel(vec2(200, 135), "", fontSize)
	    priceLabel3 = salvageTab:createLabel(vec2(200, 185), "", fontSize)
	    priceLabel4 = salvageTab:createLabel(vec2(200, 235), "", fontSize)

	    timeLabel = salvageTab:createLabel(vec2(10, 310), "", fontSize)
	end

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
    inventory:setShowScrollArrows(true, false, 1.0)

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
    Scrapyard.warnWindow = warnWindow
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
    Scrapyard.warnWindowLabel = warnWindowLabel
    warnWindowLabel.size = ihsplit.bottom.size
    warnWindowLabel:setTopAligned();
    warnWindowLabel.wordBreak = true
    warnWindowLabel.fontSize = 14


    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    warnWindow:createButton(vsplit.left, "OK"%_t, "onConfirmButtonPress")
    warnWindow:createButton(vsplit.right, "Cancel"%_t, "onCancelButtonPress")
end

-- store function safely
Scrapyard.vanillaUpdateServer = Scrapyard.updateServer
-- then overwrite with our wrapper
function Scrapyard.updateServer(timeStep)
	if Scrapyard.allowWreckageYard() == true then
		Scrapyard.vanillaUpdateServer(timeStep)
	else
		return
	end
end


print("rglx-FoundableScrapyards: loaded the modified scrapyard station!")