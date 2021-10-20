
-- overwrite existing function - adds the last two rarities to turret factories. might conflict with some stuff.
function TurretFactory.refreshBuildTurretsUI()
    local buyer = Galaxy():getPlayerCraftFaction()
    inventoryBlueprintSelection:fill(buyer.index, InventoryItemType.TurretTemplate)

    local rarities = {Rarity(RarityType.Common), Rarity(RarityType.Uncommon), Rarity(RarityType.Rare)}
    if buyer:getRelations(Faction().index) >= 80000 then
        table.insert(rarities, Rarity(RarityType.Exceptional))
        table.insert(rarities, Rarity(RarityType.Exotic)) -- added
        table.insert(rarities, Rarity(RarityType.Legendary)) -- added
    end

    local first = nil
    predefinedBlueprintSelection:clear()
    for _, weaponType in pairs(TurretFactory.getPossibleWeaponTypes()) do
        for _, rarity in pairs(rarities) do
            local item = InventorySelectionItem()
            item.item = TurretFactory.makeTurretBase(weaponType, rarity, TurretFactory.getMaterial())
            predefinedBlueprintSelection:add(item)

            if not first then first = item end
        end
    end

    selectedBlueprintSelection:clear()
    selectedBlueprintSelection:addEmpty()

    TurretFactory.placeBlueprint(first, ConfigurationMode.FactoryTurret)
end

-- overwrite existing function -- removes rarity check on buildNewTurret
function TurretFactory.buildNewTurret(weaponType, rarity, clientIngredients)
    if not CheckFactionInteraction(callingPlayer, TurretFactory.interactionThreshold) then return end

    if anynils(weaponType, rarity, clientIngredients) then return end
    if not is_type(rarity, "Rarity") then return end
    --if not (rarity.value >= 0 and rarity.value <= 3) then return end -- a single line changed for this >:(

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    if rarity.value >= RarityType.Exceptional then
        local faction = Faction()
        if faction and buyer:getRelations(faction.index) < 80000 then
            TurretFactory.sendError(player, "You need at least 'Excellent' relations to build 'Exceptional' turrets."%_t)
            return
        end
    end

    local material = TurretFactory.getMaterial()
    local station = Entity()

    -- can the weapon be built in this sector?
    local weaponProbabilities = Balancing_GetWeaponProbability(TurretFactory.getCoordinates())
    if not weaponProbabilities[weaponType] then
        TurretFactory.sendError(player, "This turret cannot be built here."%_t)
        return
    end

    -- don't take ingredients from clients blindly, they might want to cheat
    local ingredients, price, taxAmount = TurretFactory.getNewTurretIngredientsAndTax(weaponType, rarity, material, buyer)

    for i, ingredient in pairs(ingredients) do
        local other = clientIngredients[i]
        if other and other.amount then
            ingredient.amount = other.amount
        end

        if ingredient.minimum and ingredient.amount < ingredient.minimum then return end
        if ingredient.maximum and ingredient.amount > ingredient.maximum then return end
    end

    -- make sure all required goods are there
    local missing
    for i, ingredient in pairs(ingredients) do
        local good = goods[ingredient.name]:good()
        local amount = ship:getCargoAmount(good)

        if not amount or amount < ingredient.amount then
            missing = goods[ingredient.name]:good()
            break;
        end
    end

    if missing then
        TurretFactory.sendError(player, "You need more %1%."%_t, missing:pluralForm(10))
        return
    end

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        TurretFactory.sendError(player, msg, unpack(args))
        return
    end

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to build turrets."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to build turrets."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local turret = TurretFactory.makeTurret(weaponType, rarity, material, ingredients)
    local inventory = buyer:getInventory()
    if not inventory:hasSlot(turret) then
        player:sendChatMessage(Entity(), ChatMessageType.Error, "Your inventory is full (%1%/%2%)."%_T, inventory.occupiedSlots, inventory.maxSlots)
        return
    end

    -- pay
    receiveTransactionTax(station, taxAmount)

    buyer:pay("Paid %1% Credits to build a turret."%_T, price)

    for i, ingredient in pairs(ingredients) do
        local g = goods[ingredient.name]:good()
        ship:removeCargo(g, ingredient.amount)
    end

    inventory:addOrDrop(InventoryTurret(turret))

    invokeClientFunction(player, "refreshIngredientsUI")
end
callable(TurretFactory, "buildNewTurret")