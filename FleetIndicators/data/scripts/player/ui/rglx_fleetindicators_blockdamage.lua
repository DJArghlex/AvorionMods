-- namespace FleetIndicatorsBlockDamage
FleetIndicatorsBlockDamage = {}
local self = FleetIndicatorsBlockDamage -- won't work for functions

self.iconFilename = "data/textures/icons/pixel/reconstruction-site.png"
self.minimumInterval = 30 -- minimum time
self.maximumInterval = 600 -- maximum time

self.clock = 0
self.update = nil
 
-- percentages
-- anything higher than 100% known block count will show as cyan
self.percentageToTurnGreen 			 = 1.00
self.percentageToTurnGreenYellow 	 = 0.95
self.percentageToTurnYellow 		 = 0.90
self.percentageToTurnOrange 		 = 0.85
self.percentageToTurnRed 			 = 0.75

-- colors
self.colorCyan 				 = ColorRGB( 1.00, 1.00, 0.25 )
self.colorGreen 			 = ColorRGB( 0.25, 1.00, 0.25 )
self.colorGreenYellow 		 = ColorRGB( 0.62, 1.00, 0.25 )
self.colorYellow 			 = ColorRGB( 1.00, 1.00, 0.25 )
self.colorOrange 			 = ColorRGB( 1.00, 0.50, 0.25 )
self.colorRed 				 = ColorRGB( 1.00, 0.25, 0.25 )


if onClient() then
	-- all our real execution happens on the client - we shouldn't be doing anything server-side at all

	function FleetIndicatorsBlockDamage.getUpdateInterval()
		return self.minimumInterval
	end

	function FleetIndicatorsBlockDamage.initialize()
		local player = Player()
		local sector = Sector()

		-- blocks have been added or repaired or damaged
		sector:registerCallback("onBlockDestroyed","onBlocksChanged")
		sector:registerCallback("onPlanModifiedByBuilding", "onBlocksChanged")

		-- capture sector changes so we can re-issue callback requests when the player moves sectors
		player:registerCallback("onSectorChanged", "onSectorChanged")
		player:registerCallback("onSectorArrivalConfirmed", "onSectorChanged")

		-- force blockdamage update
		self.update = true
	end


	function FleetIndicatorsBlockDamage.onSectorChanged()
		local sector = Sector()

		-- blocks have been added or repaired or damaged
		sector:registerCallback("onBlockDestroyed","onBlocksChanged")
		sector:registerCallback("onPlanModifiedByBuilding", "onBlocksChanged")
	end

	function FleetIndicatorsBlockDamage.updateClient(timeStep)
		self.clock = self.clock + timeStep -- increase our clock

		if self.clock >= self.maximumInterval then
			-- if it's been more than our maximum interval then force an update
			self.update = true
		end

		-- check if we need to update
		if self.update == true then
			-- make sure we don't do it more than once
			self.update = nil
			self.clock = 0
			-- start the update
			FleetIndicatorsBlockDamage.updateAllBlockDamageIcons()
		end

	end

	function FleetIndicatorsBlockDamage.onBlocksChanged()
		-- event actually has four arguments but we really just don't need to pay attention to them
		self.update = true
	end

	function FleetIndicatorsBlockDamage.updateBlockDamageIconForOneShip(entity,owningFaction)
		if not entity then return end
		if not owningFaction then return end

		local currentResourceQuantityUsed = 0.0
		local undamagedResourceQuantityUsed = 0.0

		-- check the damaged plan
		for materialId, materialQuantity in pairs( { entity:getPlanResourceValue() } ) do
			currentResourceQuantityUsed = currentResourceQuantityUsed + materialQuantity
		end

		-- and now check the undamaged plan
		for materialId, materialQuantity in pairs( { entity:getUndamagedPlanResourceValue() } ) do
			undamagedResourceQuantityUsed = undamagedResourceQuantityUsed + materialQuantity
		end
		local percentageFlatResourceValueDifference = currentResourceQuantityUsed / undamagedResourceQuantityUsed

		local percentageMissingBlocks = 1.0
		if percentageFlatResourceValueDifference < 1.0 then
		-- method one (extremely laggy, calls multiple blockplan retrievals, both extremely bad on UI thread)
			
			local currentPlan = entity:getFullPlanCopy()
			local undamagedPlan = owningFaction:getShipPlan(entity.name)

			percentageMissingBlocks = currentPlan.numBlocks / undamagedPlan.numBlocks

			-- naughty big plan ships need to be put in the garbage collector wiggler
			local currentPlan = nil
			local undamagePlan = nil

		end



		local percentage = percentageMissingBlocks

		if percentage ~= 1.0 then
			--print("rglx_fleetindicators_blockdamage:",entity.name,"@",(percentage * 100) .. "%")
		end

		local indicator = EntityIcon(entity)

		indicator.dangerIcon = self.iconFilename
		indicator.dangerIconVisible = entity.isShip -- hide for stations unless they're being mouseovered

		if percentage > self.percentageToTurnGreen then
			indicator.dangerIconColor = self.colorCyan
			indicator.dangerIconVisible = false -- hidden at 100% (or in this case, more than 100%) block health

		elseif percentage > self.percentageToTurnGreenYellow and percentage<= self.percentageToTurnGreen then
			indicator.dangerIconColor = self.colorGreen
			indicator.dangerIconVisible = false -- hidden at 100% block health

		elseif percentage > self.percentageToTurnYellow and percentage <= self.percentageToTurnGreenYellow then
			indicator.dangerIconColor = self.colorGreenYellow

		elseif percentage > self.percentageToTurnOrange and percentage <= self.percentageToTurnYellow then
			indicator.dangerIconColor = self.colorYellow

		elseif percentage > self.percentageToTurnRed and percentage <= self.percentageToTurnOrange then
			indicator.dangerIconColor = self.colorOrange

		elseif percentage <= self.percentageToTurnRed then
			indicator.dangerIconColor = self.colorRed

		end

		indicator = nil
	end


	function FleetIndicatorsBlockDamage.updateAllBlockDamageIcons()
		local player = Player()

		for _, entity in pairs({ Sector():getEntitiesByFaction(player.index) }) do
			if entity.type == EntityType.Ship or entity.type == EntityType.Station then

				-- update block damage information
				FleetIndicatorsBlockDamage.updateBlockDamageIconForOneShip(entity,player)

			end
		end
		if player.alliance ~= nil then
			for _, entity in pairs({ Sector():getEntitiesByFaction(player.allianceIndex) }) do
				if entity.type == EntityType.Ship or entity.type == EntityType.Station then

					-- update block damage information
					FleetIndicatorsBlockDamage.updateBlockDamageIconForOneShip(entity,player.alliance)

				end
			end
		end
	end

	-- concept from rinart73's galaxy map QOL for being loaded on clientside without serverside OK
	function FleetIndicatorsBlockDamage.copyIntoOtherNamespace(targetNamespace)
		print("rglx_fleetindicators_blockdamage: sideloading into another script's namespace...")
		-- stash target namespace's updateClient function...
		rglxBlockDamage_StashedUpdateClient = targetNamespace.updateClient
		targetNamespace.updateClient = function(...)
			-- and then shim it with this, which will also run ours.
			if rglxBlockDamage_StashedUpdateClient then rglxBlockDamage_StashedUpdateClient(...) end
			FleetIndicatorsBlockDamage.updateClient(...)
		end

		-- have to stash the onSectorChanged() function. not sure how healthy it will be registering the callback twice in both .initialize()s but we'll see.
		rglxBlockDamage_StashedOnSectorChanged = targetNamespace.onSectorChanged
		targetNamespace.onSectorChanged = function(...)
			-- and then shim it with this, which will also run ours.
			if rglxBlockDamage_StashedOnSectorChanged then rglxBlockDamage_StashedOnSectorChanged(...) end
			FleetIndicatorsBlockDamage.onSectorChanged(...)
		end

		-- copy over all of our script's functions that the game will call into our new namespace.
		-- the only exception is .getUpdateInterval(). we don't want to overwrite the values present in the musiccoordinator because that tends to mess with the speed which music changes.
		-- targetNamespace.getUpdateInterval = FleetIndicatorsBlockDamage.getUpdateInterval
		targetNamespace.onBlocksChanged = FleetIndicatorsBlockDamage.onBlocksChanged

		-- now for .initialize() - we only need to run this once, and we don't need to copy it over into the new namespace.
		FleetIndicatorsBlockDamage.initialize()
	end

	print("rglx_fleetindicators_blockdamage: ready!")
	return FleetIndicatorsBlockDamage
else
	print("rglx_fleetindicators_blockdamage: loaded into server! (this does nothing)")
end