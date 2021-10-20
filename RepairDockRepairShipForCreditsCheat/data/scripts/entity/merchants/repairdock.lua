-- repair dock credits-repair cheat for hardmode.
-- allows ships to be repaired for the ludicrous credit cost normally associated with dying without a repair token.


-- namespace RepairDock

function RepairDock.refreshUI()
    -- this could get called by the server at seemingly random times, so we must check that the UI was initialized
    if not window then return end

    -- repairing
    RepairDock.refreshRepairUI()

    -- reconstruction site & kits
    RepairDock.refreshReconstructionKits()

    --if not GameSettings().reconstructionAllowed then
    --    tabbedWindow:deactivateTab(reconstructionTab)
    --else
        -- reconstructing ships
        RepairDock.refreshReconstructionLines()
    --end

end



function RepairDock.refreshReconstructionKits()

    if RepairDock.isShipyardRepairDock() then
        tabbedWindow:deactivateTab(kitsTab)
        kitsTab.description = "Only available at Repair Docks, not Shipyards!"%_t
        return
    else
        tabbedWindow:activateTab(kitsTab)
        kitsTab.description = "Reconstruction Kits"%_t
    end

    local player = Player()
    local buyer = Galaxy():getPlayerCraftFaction()
    local ship = player.craft

    reconstructionPriceLabel.caption = "Price: ¢${money}"%_t % {money = createMonetaryString(RepairDock.getReconstructionSiteChangePrice())}

    if buyer.isAlliance then
        setReconstructionSiteButton.active = false
        setReconstructionSiteButton.tooltip = "Alliances don't have reconstruction sites."%_t
    elseif RepairDock.isReconstructionSite() then
        setReconstructionSiteButton.active = false
        setReconstructionSiteButton.tooltip = "This sector is already your reconstruction site."%_t
    elseif not CheckFactionInteraction(buyer.index, 60000) then
        setReconstructionSiteButton.active = false
        setReconstructionSiteButton.tooltip = "We only offer these kinds of services to people we have relations of at least 60,000 with."%_t
    else
        setReconstructionSiteButton.active = true
        setReconstructionSiteButton.tooltip = nil
    end

    local previous = buyKitNameCombo.selectedValue
    buyKitNameCombo:clear()

    --buyKitNameCombo.active = GameSettings().reconstructionAllowed
    --buyKitButton.active = GameSettings().reconstructionAllowed
    --buyKitAmountLabel.active = GameSettings().reconstructionAllowed
    --buyKitAmountLabel.caption = ""
    --buyKitPriceLabel.active = GameSettings().reconstructionAllowed

    buyKitNameCombo.active = true
    buyKitButton.active = true
    buyKitAmountLabel.active = true
    buyKitAmountLabel.caption = ""
    buyKitPriceLabel.active = true

    --if GameSettings().reconstructionAllowed then
        local names = {buyer:getShipNames()}
        for _, name in pairs(names) do
            local kits = countReconstructionKits(player, name, buyer.index)
            local akits = 0

            local alliance = player.alliance
            if alliance then
                akits = countReconstructionKits(alliance, name, buyer.index)
            end

            if kits == 0 and akits == 0 then
                buyKitNameCombo:addEntry(name, name, ColorRGB(0.9, 0.9, 0.9))
            else
                buyKitNameCombo:addEntry(name, name, ColorRGB(0.5, 0.5, 0.5))
            end
        end

        if previous then
            buyKitNameCombo.selectedValue = previous
        end
        RepairDock.onShipNameSelected()

        buyKitButton.active = (#names > 0)

        local price = RepairDock.getReconstructionKitPrice(buyer)
        buyKitPriceLabel.caption = createMonetaryString(price)
        buyKitPriceLabel.color = ColorRGB(1, 1, 1)
        buyKitPriceLabel.tooltip = nil
    --else
    --    buyKitAmountLabel.caption = "-"
    --    buyKitPriceLabel.caption = "-"
    --    buyKitButton.tooltip = nil
    --    priceDescriptionLabel1:hide()
    --end
end


function RepairDock.reconstruct(shipName, allianceShip)

    if not CheckFactionInteraction(callingPlayer, RepairDock.interactionThreshold) then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.ManageShips, AlliancePrivilege.SpendItems)
    if not buyer then return end

    -- if we're requesting an alliance ship to be rebuilt and the buyer is a player, then switch the buyer to be the alliance instead
    if allianceShip == true and buyer.isPlayer and buyer.alliance then
        local alliance = buyer.alliance

        -- we still have to check for privileges
        local requiredPrivileges = {AlliancePrivilege.ManageShips, AlliancePrivilege.SpendItems}
        for _, privilege in pairs(requiredPrivileges) do
            if not alliance:hasPrivilege(callingPlayer, privilege) then
                player:sendChatMessage("", 1, "You don't have permission to do that in the name of your alliance."%_t)
                return
            end
        end

        buyer = player.alliance
    elseif allianceShip == false and buyer.isAlliance then
        buyer = player
    end

    if RepairDock.isShipyardRepairDock() then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Shipyards don't offer these kinds of services."%_T)
        return
    end

    -- reconstructing stations is not possible
    if buyer:getShipType(shipName) ~= EntityType.Ship then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Can only reconstruct ships."%_T)
        return
    end

    --if not GameSettings().reconstructionAllowed then
    --    player:sendChatMessage(Entity(), ChatMessageType.Error, "Reconstruction impossible."%_T)
    --    return
    --end

    -- reconstructing non-destroyed ships is impossible
    if not buyer:getShipDestroyed(shipName) then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Ship wasn't destroyed."%_T)
        return
    end

    local price, error = RepairDock.getTowingPrice(buyer, shipName)
    if error then
        player:sendChatMessage(Entity(), ChatMessageType.Error, error)
        return
    end

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        player:sendChatMessage(Entity(), ChatMessageType.Error, msg, unpack(args))
        return
    end

    buyer:pay("Paid %1% Credits to reconstruct a ship."%_T, price)

    -- find a position to put the craft
    local position = Matrix()
    local station = Entity()
    local box = buyer:getShipBoundingBox(shipName)

    -- try putting the ship at a dock
    local docks = DockingPositions(station)
    local dockIndex = docks:getFreeDock()
    if dockIndex then
        local dock = docks:getDockingPosition(dockIndex)
        local pos = vec3(dock.position.x, dock.position.y, dock.position.z)
        local dir = vec3(dock.direction.x, dock.direction.y, dock.direction.z)

        pos = station.position:transformCoord(pos)
        dir = station.position:transformNormal(dir)

        pos = pos + dir * (box.size.z / 2 + 10)

        local up = station.position.up

        position = MatrixLookUpPosition(-dir, up, pos)
    else
        -- if all docks are occupied, place it near the station
        -- use the same orientation as the station
        position = station.orientation

        local sphere = station:getBoundingSphere()
        position.translation = sphere.center + random():getDirection() * (sphere.radius + length(box.size) / 2 + 50);
    end

    local sx, sy = buyer:getShipPosition(shipName)
    local x, y = Sector():getCoordinates()

    local craft = buyer:restoreCraft(shipName, position, true)
    if not craft then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Error reconstructing craft."%_t)
        return
    end

    CargoBay(craft):clear()
    craft:setValue("untransferrable", nil) -- tutorial could have broken this

    if ship.isDrone then
        player.craft = craft
        invokeClientFunction(player, "transactionComplete")
    end

    if Balancing_InsideRing(sx, sy) and not Balancing_InsideRing(x, y) then
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "Towing & Reconstruction complete! Thanks to your instructions, we found the wormhole to the center. That was a wild ride!"%_t)
    else
        Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "Towing & Reconstruction complete!"%_t)
    end

    Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "We also offer very affordable repair services if you are interested!"%_t)

    invokeClientFunction(player, "refreshUI")
end
callable(RepairDock, "reconstruct")