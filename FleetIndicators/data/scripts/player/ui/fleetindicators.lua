-- namespace FleetIndicators
FleetIndicators = {}
FleetIndicators.updateTimer = 0
FleetIndicators.maximumUpdateTimer = 120 -- max time between full updates of block counts
FleetIndicators.updateInterval = 4 -- minimum time between full updates of block counts
FleetIndicators.blockDamageUpdateRequired = nil
FleetIndicators.orderInfoUpdateRequired = nil

if onClient() then
	-- all our real execution happens on the client - we shouldn't be doing anything server-side at all

	-- from https://stackoverflow.com/a/22831842
	function startsWith(String,Start)
		return string.sub(String,1,string.len(Start))==Start
	end

	function FleetIndicators.getUpdateInterval()
		-- every two seconds, check if we need to update. this should cut down on lag.
		return FleetIndicators.updateInterval
	end

	function FleetIndicators.initialize()
		local player = Player()
		local sector = Sector()

		-- personal ship orders have updated
		player:registerCallback("onShipOrderInfoUpdated", "onShipOrderInfoUpdated")

		-- alliance ship orders have updated
		if player.alliance then
			player.alliance:registerCallback("onShipOrderInfoUpdated", "onAllianceShipOrderInfoUpdated")
		end

		-- force orders update
		FleetIndicators.orderInfoUpdateRequired = true

		-- blocks have been added or repaired or damaged
		sector:registerCallback("onBlockDestroyed","onBlocksChanged")
		sector:registerCallback("onPlanModifiedByBuilding", "onBlocksChanged")

		-- capture sector changes so we can re-issue callback requests when the player moves sectors
		player:registerCallback("onSectorChanged", "onSectorChanged")
		player:registerCallback("onSectorArrivalConfirmed", "onSectorChanged")
	end


	function FleetIndicators.onSectorChanged()
		local sector = Sector()

		-- force orders update
		FleetIndicators.orderInfoUpdateRequired = true

		-- blocks have been added or repaired or damaged
		sector:registerCallback("onBlockDestroyed","onBlocksChanged")
		sector:registerCallback("onPlanModifiedByBuilding", "onBlocksChanged")
	end

	function FleetIndicators.updateClient(timeStep)
		FleetIndicators.updateTimer = FleetIndicators.updateTimer + timeStep

		if FleetIndicators.updateTimer > FleetIndicators.maximumUpdateTimer then
			FleetIndicators.blockDamageUpdateRequired = true
			FleetIndicators.orderInfoUpdateRequired = true
		end

		if FleetIndicators.blockDamageUpdateRequired then

			FleetIndicators.updateAllBlockDamageIcons()

			-- reset updateTimer after updating the icons
			FleetIndicators.updateTimer = 0
			FleetIndicators.blockDamageUpdateRequired = nil
		end

		if FleetIndicators.orderInfoUpdateRequired then

			FleetIndicators.updateAllOrderIcons()

			FleetIndicators.orderInfoUpdateRequired = nil
		end

	end

	function FleetIndicators.onBlocksChanged() --(entityIndex)
		-- onBlockDestroyed has four more arguments but they're unneccessary here

		-- the reason we're not doing things below with a call to Entity() is because that would be a lot of extra calls to Entity() for the game to try and run, e.g. a lot of block-damage suddenly going out would mean Entity() being called for *every single block* destroyed regardless of whose ship it's on
		-- this is very bad. don't do it.

		--local entity = Entity(entityIndex)
		--local player = Player()
		--if entity.factionIndex == player.index or entity.factionIndex == player.allianceIndex then
			-- we only want to update if we're 
			FleetIndicators.blockDamageUpdateRequired = true
		--end
	end

	function FleetIndicators.onShipOrderInfoUpdated(entityName,entityOrder)
		local player = Player()
		FleetIndicators.updateOrderIconForOneShip(entityName,entityOrder,player.index)
	end

	function FleetIndicators.onAllianceShipOrderInfoUpdated(entityName,entityOrder)
		local player = Player()
		FleetIndicators.updateOrderIconForOneShip(entityName,entityOrder,player.allianceIndex)
	end

	function FleetIndicators.updateOrderIconForOneShip(entityName,orderInfo,entityOwnerIndex)
		local owner = Faction(entityOwnerIndex)
		if not owner then return end

		local player = Player()
		local currentActivity = nil
		if owner.index == player.index then
			currentActivity = player:getShipStatus(entityName)
		elseif owner.index == player.allianceIndex then
			currentActivity = player.alliance:getShipStatus(entityName)
		else
			return -- not for our player or alliance fleet
		end



		local entity = Sector():getEntityByFactionAndName(owner.index,entityName)
		if not entity then return end -- if we couldn't find the entity, it's not in this sector or otherwise unavailable
		if currentActivity ~= "[PLAYER]" and currentActivity ~= "" and currentActivity ~= "Idle" and currentActivity ~= nil then
			print("rglx-FleetIndicators: orderinfo",entity.name,"@",currentActivity)
		end
		local indicator = EntityIcon(entity)

		if currentActivity == "Idle" then -- no longer doing something
			indicator.secondaryIcon = ""

		elseif currentActivity == "Patrolling Sector" then -- autonomously patrolling the sector
			indicator.secondaryIcon = "data/textures/icons/pixel/patrol.png" 

		elseif currentActivity == "Flying to Position" then -- moving to a position in sector
			indicator.secondaryIcon = "data/textures/icons/pixel/flytoposition.png" 

		elseif currentActivity == "Guarding Position" then -- guarding an exact position in sector
			indicator.secondaryIcon = "data/textures/icons/pixel/guard.png"

		--elseif startsWith(currentActivity, "[PLAYER]") then -- occupied by a player (NOTE: this can show regardless of ship's activity!)
			--indicator.secondaryIcon = "data/textures/icons/pixel/groupmember.png"

		elseif startsWith(currentActivity, "Attacking ") then -- attacking something or waiting to attack something
			if currentActivity == "Attacking Enemies" then
				indicator.secondaryIcon = "data/textures/icons/pixel/attacking.png"
			else
				indicator.secondaryIcon = "data/textures/icons/pixel/persecutor.png"
			end

		elseif startsWith(currentActivity, "Boarding") then -- boarding a ship
			indicator.secondaryIcon = "data/textures/icons/pixel/boarding.png"

		elseif startsWith(currentActivity, "Escorting") then -- escorting a ship
			indicator.secondaryIcon = "data/textures/icons/pixel/escort.png"

		elseif startsWith(currentActivity, "Repairing") then -- conducting repairs on another ship
			indicator.secondaryIcon = "data/textures/icons/pixel/repair.png"

		elseif startsWith(currentActivity, "Salvaging") then -- salvaging something
			indicator.secondaryIcon = "data/textures/icons/pixel/salvaging.png"

		elseif startsWith(currentActivity, "Mining") then -- mining something
			indicator.secondaryIcon = "data/textures/icons/pixel/mining.png"

		elseif startsWith(currentActivity, "Flying Through") then -- passing through a gate or similar
			indicator.secondaryIcon = "data/textures/icons/pixel/vortex.png"

		elseif startsWith(currentActivity, "Jumping") then -- preparing to jump
			indicator.secondaryIcon = "data/textures/icons/pixel/vortex.png"

		elseif startsWith(currentActivity, "Refining") then -- refining ores
			indicator.secondaryIcon = "data/textures/icons/pixel/refine.png"
		end

		-- blocking issues in current activity- show a red ! so they can be reassigned
		if startsWith(currentActivity, "Salvaging - ") 
			or startsWith(currentActivity, "Mining - ")
			or startsWith(currentActivity, "Boarding - ")
			or startsWith(currentActivity, "Refining Ores - Waiting For Processing") -- better for reassigning ships that're done dropping off
			or startsWith(currentActivity, "Repairing - ")
		then
			indicator.tertiaryIcon = "data/textures/icons/pixel/mission-white.png"
			indicator.tertiaryIconColor = ColorRGB(1.0,0.25,0.25)
		else -- no errors present- let's clear and move on.
			indicator.tertiaryIcon = ""
			indicator.tertiaryIconColor = ColorRGB(1.0,1.0,1.0)
		end

	end

	function FleetIndicators.updateBlockDamageIconForOneShip(entity)
		-- we're assuming this entity we're being given is for sure one of ours- no unneccessary calls to Player() or anything we can't avoid

		-- method three (raw resource counts, added together, then divided for percentage. generally speaking, all blocktypes use the same quantity of material regardless if it's iron or avorion)
		-- this will be the most reliable
		local currentResourceQuantityUsed = 0.0
		local undamagedResourceQuantityUsed = 0.0
		for materialId, materialQuantity in pairs( { entity:getPlanResourceValue() } ) do
			currentResourceQuantityUsed = currentResourceQuantityUsed + materialQuantity
		end
		for materialId, materialQuantity in pairs( { entity:getUndamagedPlanResourceValue() } ) do
			undamagedResourceQuantityUsed = undamagedResourceQuantityUsed + materialQuantity
		end
		local percentageFlatResourceValueDifference = currentResourceQuantityUsed / undamagedResourceQuantityUsed

		local percentageMissingBlocks = 1.0
		if percentageFlatResourceValueDifference < 1.0 then
		-- method one (extremely laggy, calls multiple blockplan retrievals, both extremely bad on UI thread)
			
			local player = Player()
			if player.index == entity.factionIndex then
				owningFaction = player
			elseif entity.factionIndex == player.allianceIndex then
				owningFaction = player.alliance
			else
				return -- update is for a ship we don't own
			end
			percentageMissingBlocks = entity:getFullPlanCopy().numBlocks / owningFaction:getShipPlan(entity.name).numBlocks
		end


		-- method two. mostly inaccurate, but simple, however one missing avorion hyperspace core or assembly block would show much more damage to the ship than a large amount of damage to dumb-hulls or armor of a lower grade
		--local percentageMoneyValueDifference = entity:getPlanMoneyValue() / entity:getUndamagedPlanMoneyValue()


		-- method four (resource counts, converted to credits using material's galactic average, then divided. has the same problem as method two.)
		--[[
		local currentConvertedResourcesUsed = 0.0
		local undamagedConvertedResourcesUsed = 0.0
		for materialId, materialQuantity in pairs( { entity:getPlanResourceValue() } ) do
			currentConvertedResourcesUsed = currentConvertedResourcesUsed + ( materialQuantity * Material(materialId).costFactor )
		end
		for materialId, materialQuantity in pairs( { entity:getUndamagedPlanResourceValue() } ) do
			undamagedConvertedResourcesUsed = undamagedConvertedResourcesUsed + ( materialQuantity * Material(materialId).costFactor )
		end
		local percentageConvertedResourceValueDifference = currentConvertedResourcesUsed / undamagedConvertedResourcesUsed
		--]]

		-- anything higher than 100% known block count will show as cyan
		local percentageToTurnGreen 		 = 1.00
		local percentageToTurnGreenYellow 	 = 0.95
		local percentageToTurnYellow 		 = 0.90
		local percentageToTurnOrange 		 = 0.85
		local percentageToTurnRed 			 = 0.75 -- 75% block count is where the icon changes from yellow to red

		local percentage = percentageMissingBlocks

		if percentage ~= 1.0 then
			print("rglx-FleetIndicators: blockdamage",entity.name,"@",(percentage * 100) .. "%")
		end

		local indicator = EntityIcon(entity)

		-- i like this one because it's small and not big and blaring. there'll be lots of these on-screen
		indicator.dangerIcon = "data/textures/icons/pixel/reconstruction-site.png"
		

		if percentage > percentageToTurnGreen then
			indicator.dangerIconColor = ColorRGB( 1.00, 1.00, 0.25 ) -- cyan
			indicator.dangerIconVisible = false -- mouseovering a station will still show them, but by default they'll be hidden.

		elseif percentage > percentageToTurnGreenYellow and percentage<= percentageToTurnGreen then
			indicator.dangerIconColor = ColorRGB( 0.25, 1.00, 0.25 ) -- green
			indicator.dangerIconVisible = false -- mouseovering a station will still show them, but by default they'll be hidden.

		elseif percentage > percentageToTurnYellow and percentage <= percentageToTurnGreenYellow then
			indicator.dangerIconColor = ColorRGB( 0.62, 1.00, 0.25 ) -- green-yellow
			indicator.dangerIconVisible = entity.isShip -- mouseovering a station will still show them, but by default they'll be hidden.

		elseif percentage > percentageToTurnOrange and percentage <= percentageToTurnYellow then
			indicator.dangerIconColor = ColorRGB( 1.00, 1.00, 0.25 ) -- yellow
			indicator.dangerIconVisible = entity.isShip -- mouseovering a station will still show them, but by default they'll be hidden.

		elseif percentage > percentageToTurnRed and percentage <= percentageToTurnOrange then
			indicator.dangerIconColor = ColorRGB( 1.00, 0.50, 0.25 ) -- orange
			indicator.dangerIconVisible = entity.isShip -- mouseovering a station will still show them, but by default they'll be hidden.

		elseif percentage <= percentageToTurnRed then
			indicator.dangerIconColor = ColorRGB( 1.00, 0.25, 0.25 ) -- red
			indicator.dangerIconVisible = entity.isShip -- mouseovering a station will still show them, but by default they'll be hidden.

		end

	end


	function FleetIndicators.updateAllBlockDamageIcons()
		local player = Player()

		for _, entity in pairs({ Sector():getEntitiesByFaction(player.index) }) do
			if entity.type == EntityType.Ship or entity.type == EntityType.Station then

				-- update block damage information
				FleetIndicators.updateBlockDamageIconForOneShip(entity)

			end
		end
		if player.alliance ~= nil then
			for _, entity in pairs({ Sector():getEntitiesByFaction(player.allianceIndex) }) do
				if entity.type == EntityType.Ship or entity.type == EntityType.Station then

					-- update block damage information
					FleetIndicators.updateBlockDamageIconForOneShip(entity)

				end
			end
		end
	end

	function FleetIndicators.updateAllOrderIcons()
		local player = Player()

		for _, entity in pairs({ Sector():getEntitiesByFaction(player.index) }) do
			if entity.type == EntityType.Ship or entity.type == EntityType.Station then

				-- update order icon information
				FleetIndicators.updateOrderIconForOneShip(entity.name,player:getShipOrderInfo(entity.name),player.index)

			end
		end
		if player.alliance ~= nil then
			for _, entity in pairs({ Sector():getEntitiesByFaction(player.allianceIndex) }) do
				if entity.type == EntityType.Ship or entity.type == EntityType.Station then

					-- update order icon information
					FleetIndicators.updateOrderIconForOneShip(entity.name,player.alliance:getShipOrderInfo(entity.name),player.allianceIndex)

				end
			end
		end
	end

	print("rglx-FleetIndicators: loaded into client!")
end