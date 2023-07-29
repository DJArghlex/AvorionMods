-- namespace FleetIndicatorsCraftStatus
FleetIndicatorsCraftStatus = {}
local self = FleetIndicatorsCraftStatus

-- /run Player():removeScript("ui/rglx_fleetindicators_craftstatus")
-- /run Player():addScriptOnce("ui/rglx_fleetindicators_craftstatus") 

-- order to icon & color settings
-- exact matches are processed last, meaning they'll take precedence over startsWith() matches
-- { "string from owningFaction:getShipStatus(entity.name)", "<icon file to use>", ColorRGB() of your choice }

-- order info icon settings 

self.colorOrder 					 = ColorRGB( 0.7, 0.7, 0.7 ) -- color for order's icon
self.colorBlockingIssue 			 = ColorRGB( 1.00, 0.25, 0.25 ) -- color for a blocking issue (not enough boarders, nothing refineable)
self.colorNonBlockingIssue 			 = ColorRGB( 1.00, 1.00, 0.25 ) -- color for a non-blocking issue (refinery already in use, crew issues)

-- compares the order info to entry's first field using lua '==' behavior, then last matching one is used.
self.ordersToIconsExactMatch = {
	{ "Idle", "" }, -- removes icon entirely
	{ "Attacking Enemies", 	 "data/textures/icons/pixel/attacking.png", 	 self.colorOrder }, -- crossed swords icon
	{ "Patrolling Sector", 	 "data/textures/icons/pixel/patrol.png", 	 self.colorOrder }, -- points with line between
	{ "Flying to Position", 	 "data/textures/icons/pixel/flytoposition.png", 	 self.colorOrder }, -- basically a skip icon
	{ "Guarding Position", 	 "data/textures/icons/pixel/guard.png", 	 self.colorOrder }, -- shield icon

}

-- compares the order info to entry's first field using startsWith(), then last matching one is used.
self.ordersToIconsStartsWith = {
	{ "Attacking ", 	 "data/textures/icons/pixel/persecutor.png", 	 self.colorOrder }, -- closest thing to 'focus on a target' i could find
	{ "Boarding", 	 "data/textures/icons/pixel/boarding.png", 	 self.colorOrder },
	{ "Escorting", 	 "data/textures/icons/pixel/escort.png", 	 self.colorOrder },
	{ "Repairing", 	 "data/textures/icons/pixel/repair.png", 	 self.colorOrder },
	{ "Salvaging", 	 "data/textures/icons/pixel/salvaging.png", 	 self.colorOrder },
	{ "Mining", 	 "data/textures/icons/pixel/mining.png", 	 self.colorOrder },
	{ "Flying Through", 	 "data/textures/icons/pixel/vortex.png", 	 self.colorOrder },
	{ "Jumping", 	 "data/textures/icons/pixel/vortex.png", 	 self.colorOrder },
	{ "Refining", 	 "data/textures/icons/pixel/refine.png", 	 self.colorOrder }, -- using instead of the 'stack of bricks' icon
}


-- same deal here, but these handle the craft status icon (the tertiary icon slot)
self.ordersToProblemsExactMatch = {
	{ "Refining Ores - Waiting For Processing", 	 "data/textures/icons/pixel/sleep.png", 	 self.colorNonBlockingIssue },
}
self.ordersToProblemsStartsWith = {
	{ "Refining Ores - ", 	 "data/textures/icons/pixel/exclamation-mark.png", 	 self.colorBlockingIssue },
	{ "Salvaging - ", 	 "data/textures/icons/pixel/exclamation-mark.png", 	 self.colorBlockingIssue },
	{ "Mining - ", 	 "data/textures/icons/pixel/exclamation-mark.png", 	 self.colorBlockingIssue },
	{ "Boarding - ", 	 "data/textures/icons/pixel/exclamation-mark.png", 	 self.colorBlockingIssue },
	{ "Repairing - ", 	 "data/textures/icons/pixel/exclamation-mark.png", 	 self.colorBlockingIssue },
}


self.minimumInterval = 0.5
self.maximumInterval = 2.0
self.clock = 0
self.update = nil


if onClient() then
	-- all our real execution happens on the client - we shouldn't be doing anything server-side at all

	-- from https://stackoverflow.com/a/22831842
	function startsWith(String,Start)
		return string.sub(String,1,string.len(Start))==Start
	end

	function FleetIndicatorsCraftStatus.getUpdateInterval()
		return self.minimumInterval
	end

	function FleetIndicatorsCraftStatus.initialize()
		local player = Player()
		local sector = Sector()

		-- install a callback for when personal ship orders have updated
		player:registerCallback("onShipOrderInfoUpdated", "onShipOrderInfoUpdated")

		-- install a callback for when alliance ship orders have updated
		if player.alliance then
			player.alliance:registerCallback("onShipOrderInfoUpdated", "onShipOrderInfoUpdated")
		end

		-- force orders update
		self.update = true
	end

	function FleetIndicatorsCraftStatus.updateClient(timeStep)
		self.clock = self.clock + timeStep

		if self.clock >= self.maximumInterval then
			self.update = true
		end

		if self.update == true then
			self.update = nil
			self.clock = 0
			FleetIndicatorsCraftStatus.updateAllOrderIcons()
		end
	end

	function FleetIndicatorsCraftStatus.onShipOrderInfoUpdated()
		self.update = true
	end

	function FleetIndicatorsCraftStatus.updateOrderIconForOneShip(entity,owningFaction)
		if not entity then return end
		if not owningFaction then return end

		local currentActivity = owningFaction:getShipStatus(entity.name)

		if currentActivity ~= "[PLAYER]" and currentActivity ~= "" and currentActivity ~= "Idle" and currentActivity ~= nil then
			--print("rglx_fleetindicators_orderinfo:",entity.name,"@",currentActivity)
		end

		-- set up some initial variables
		local orderIconToUse = ""
		local statusIconToUse = ""
		local orderIconColorToUse = ColorRGB(1,1,1)
		local statusIconColorToUse = ColorRGB(1,1,1)

		-- do our order icons

		for _, entry in ipairs(self.ordersToIconsStartsWith) do
			if startsWith(currentActivity,entry[1]) then
				orderIconToUse = entry[2]
				orderIconColorToUse = entry[3]
			end
		end

		-- we want exact matches to take precedence because of "Attacking Enemies" matching our comparison above for the 'Attacking <ship name>' string
		for _, entry in ipairs(self.ordersToIconsExactMatch) do
			if currentActivity == entry[1] then
				orderIconToUse = entry[2]
				orderIconColorToUse = entry[3]
			end
		end


		-- do our status icons next

		for _, entry in ipairs(self.ordersToProblemsStartsWith) do
			if startsWith(currentActivity,entry[1]) then
				statusIconToUse = entry[2]
				statusIconColorToUse = entry[3]
			end
		end
		-- same thing. non-exact first, then override with exact matches.
		for _, entry in ipairs(self.ordersToProblemsExactMatch) do
			if currentActivity == entry[1] then
				statusIconToUse = entry[2]
				statusIconColorToUse = entry[3]
			end
		end

		-- ok, now let's set some icons up.
		local indicator = EntityIcon(entity)

		-- finally, set our icons
		indicator.secondaryIcon = orderIconToUse
		indicator.tertiaryIcon = statusIconToUse
		--indicator.secondaryIconColor = orderIconColorToUse
		--indicator.tertiaryIconColor = statusIconColorToUse

		indicator = nil -- feed to the garbage collector

	end

	function FleetIndicatorsCraftStatus.updateAllOrderIcons()
		local player = Player()

		for _, entity in pairs({ Sector():getEntitiesByFaction(player.index) }) do
			if entity.type == EntityType.Ship or entity.type == EntityType.Station then

				-- update order icon information
				FleetIndicatorsCraftStatus.updateOrderIconForOneShip(entity,player)

			end
		end
		if player.alliance ~= nil then
			for _, entity in pairs({ Sector():getEntitiesByFaction(player.allianceIndex) }) do
				if entity.type == EntityType.Ship or entity.type == EntityType.Station then

					-- update order icon information
					FleetIndicatorsCraftStatus.updateOrderIconForOneShip(entity,player.alliance)

				end
			end
		end
	end

	-- concept from rinart73's galaxy map QOL for being loaded on clientside without serverside OK
	function FleetIndicatorsCraftStatus.copyIntoOtherNamespace(targetNamespace)
		print("rglx_fleetindicators_orderinfo: sideloading into another script's namespace...")
		-- stash target namespace's updateClient function...
		rglxCraftStatus_StashedUpdateClient = targetNamespace.updateClient
		targetNamespace.updateClient = function(...)
			-- and then shim it with this, which will also run ours.
			if rglxCraftStatus_StashedUpdateClient then rglxCraftStatus_StashedUpdateClient(...) end
			FleetIndicatorsCraftStatus.updateClient(...)
		end

		-- copy over all of our script's functions that the game will call into our new namespace.
		-- the only exception is .getUpdateInterval(). we don't want to overwrite the values present in the musiccoordinator because that tends to mess with the speed which music changes.
		-- targetNamespace.getUpdateInterval = FleetIndicatorsCraftStatus.getUpdateInterval
		targetNamespace.onShipOrderInfoUpdated = FleetIndicatorsCraftStatus.onShipOrderInfoUpdated

		-- now for .initialize() - we only need to run this once, and we don't need to copy it over into the new namespace.
		FleetIndicatorsCraftStatus.initialize()
	end


	print("rglx_fleetindicators_orderinfo: ready!")
	return FleetIndicatorsCraftStatus
else
	print("rglx_fleetindicators_orderinfo: loaded into server! (this does nothing)")
end