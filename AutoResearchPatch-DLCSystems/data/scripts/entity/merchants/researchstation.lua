autoResearchDlcFixes_dlcSystemScriptNames = {
	"badcargowarningsystem" = "blackmarket",
	"cargodetectionscrambler" = "blackmarket",
	"hackingupgrade" = "blackmarket"
}

function ResearchStation.autoResearch_autoResearch(maxRarity, itemType, selectedTypes, materialType, minAmount, maxAmount, separateAutoTurrets)
	maxRarity = tonumber(maxRarity)
	itemType = tonumber(itemType)
	materialType = tonumber(materialType)
	if anynils(maxRarity, itemType, selectedTypes, materialType) then return end
	minAmount = tonumber(minAmount) or 5
	maxAmount = tonumber(maxAmount) or 5
	minAmount = math.min(minAmount, maxAmount)
	maxAmount = math.max(minAmount, maxAmount)

	local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
	if not player then return end
	if not buyer then
		invokeClientFunction(player, "autoResearch_autoResearchComplete")
		return
	end

	if autoResearch_playerLocks[callingPlayer] then -- auto research is already going
		invokeClientFunction(player, "autoResearch_autoResearchComplete")
		return
	end
	autoResearch_playerLocks[callingPlayer] = true
	
	-- Get System Upgrade script path from selectedIndex
	if itemType == 0 then
		local selectedSystems = {}
		for systemType in pairs(selectedTypes) do
			systemType = autoResearch_systemTypeScripts[math.max(1, math.min(#autoResearch_systemTypeScripts, systemType))]

			-- code below here changed for blackmarket dlc by rglx
			-- the reason i'm adding a separate entry
			for dlcSystem, dlcSource in pairs(autoResearchDlcFixes_dlcSystemScriptNames) do
				if dlcSystem == systemType then -- we found a dlc system
					selectedSystems["internal/dlc/".. dlcSource .."/systems/".. systemType ..".lua"] = true
				else -- ok it's not from the DLC so just add it under the normal scripts directory
					selectedSystems["data/scripts/systems/".. systemType ..".lua"] = true
				end	
			end
		end
		selectedTypes = selectedSystems
	end

	if materialType == -1 then
		materialType = nil
	end

	local inventory = buyer:getInventory() -- get just once
	AutoResearchLog:Debug("Player %i - Research started", callingPlayer)
	local result = deferredCallback(0, "autoResearch_deferred", callingPlayer, inventory, separateAutoTurrets, maxRarity, minAmount, maxAmount, itemType, selectedTypes, materialType, {{},{}})
	if not result then
		AutoResearchLog:Error("Player %i - Failed to defer research", callingPlayer)
		autoResearch_playerLocks[callingPlayer] = nil
		invokeClientFunction(player, "autoResearch_autoResearchComplete")
	end
end
callable(ResearchStation, "autoResearch_autoResearch")