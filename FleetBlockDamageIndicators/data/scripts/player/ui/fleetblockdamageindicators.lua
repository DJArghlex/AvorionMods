-- namespace FleetBlockDamageIndicators
FleetBlockDamageIndicators = {}
FleetBlockDamageIndicators.iconRefreshRequired = nil
FleetBlockDamageIndicators.updateTimer = 0
FleetBlockDamageIndicators.maximumUpdateInterval = 60
FleetBlockDamageIndicators.cachedShipBlockCounts = {} -- cache our plans' block counts in this

if onClient() then
	-- all our real execution happens on the client - we shouldn't be doing anything server-side at all

	function FleetBlockDamageIndicators.getUpdateInterval()
		return 1
	end

	function FleetBlockDamageIndicators.initialize()
		local player = Player()
		local sector = Sector()
		local craft = player.craft

		player:registerCallback("onShipChanged", "onRefreshRequired")
		player:registerCallback("onSectorChanged", "onSectorChanged")
		player:registerCallback("onSectorArrivalConfirmed", "onSectorChanged")
		sector:registerCallback("onEntityCreated", "onRefreshRequired")
		sector:registerCallback("onPlanModifiedByBuilding", "onRefreshRequired")
	end

	function FleetBlockDamageIndicators.onSectorChanged()
		local sector = Sector()
		sector:registerCallback("onEntityCreated", "onRefreshRequired")
		sector:registerCallback("onPlanModifiedByBuilding", "onRefreshRequired")
		sector:registerCallback("onBlocksAdded", "onRefreshRequired")
		FleetBlockDamageIndicators.iconRefreshRequired = true
	end

	function FleetBlockDamageIndicators.onRefreshRequired()
		FleetBlockDamageIndicators.iconRefreshRequired = true
	end

	function FleetBlockDamageIndicators.updateClient(timeStep)
		FleetBlockDamageIndicators.updateTimer = FleetBlockDamageIndicators.updateTimer + timeStep

		if FleetBlockDamageIndicators.updateTimer > FleetBlockDamageIndicators.maximumUpdateInterval then
			FleetBlockDamageIndicators.iconRefreshRequired = true
		end

		if FleetBlockDamageIndicators.iconRefreshRequired then
			FleetBlockDamageIndicators.updateShipIcons()

			-- reset updateTimer after updating the icons
			FleetBlockDamageIndicators.updateTimer = 0
			FleetBlockDamageIndicators.iconRefreshRequired = nil
		end

		FleetBlockDamageIndicators.updateTimer = FleetBlockDamageIndicators.updateTimer + 1
	end

	function FleetBlockDamageIndicators.updateShipIcons()
		local player = Player()
		local craft = player.craft
		if not craft then return end

		for _, entity in pairs({Sector():getEntitiesByComponent(ComponentType.Turrets)}) do
			-- only retrieve things that are armed
			if entity.factionIndex == player.index or entity.factionIndex == player.allianceIndex then
				if entity.type == EntityType.Ship then

					-- only do things if this is a player/player's alliance-owned ship that is armed. anything else is redundant.

					local indicator = EntityIcon(entity)
					indicator.dangerIconColor = ColorHSV(0.0,0.0,1.0) -- set to white so we know it's updating
					indicator.dangerIcon = "data/textures/icons/pixel/reconstruction-site.png"
					indicator.dangerIconVisible = true

					print(entity.name .. " retrieving block plans - 0")
					local currentBlockPlan = entity:getFullPlanCopy()
					print(entity.name .. " retrieving block plans - 1")
					local originalBlockPlan = player:getShipPlan(entity.name)
					print(entity.name .. " retrieving block plans - 2")

					local percentageOfBlocksRemaining = currentBlockPlan.numBlocks / originalBlockPlan.numBlocks

					print(entity.name .. " at " .. percentageOfBlocksRemaining .. "% block count!")

					if percentageOfBlocksRemaining < 0.5 then
						percentageOfBlocksRemaining = 0.5 -- more than half of the blocks have been damaged. this is *bad*
					end


					if percentageOfBlocksRemaining > 1.0 then
						indicator.dangerIconColor = ColorHSV(240/360,0.5,1.0) -- more blocks than expected? go with blue.
					else
						-- do some silly-ass math to make a 0.5->1.0 value for our hue, between 0 and 120
						indicator.dangerIconColor = ColorHSV( ( ( 1 - ( percentageOfBlocksRemaining * 2.0 ) ) * 120 ) / 360 ,0.5,1.0)
					end


				end
			end
		end
	end

else
	print("rglx-FleetBlockDamageIndicators: this should NOT be loaded on your server! add it to your allowedMods table in modconfig.lua instead. if you're playing singleplayer, don't worry about it.")
end