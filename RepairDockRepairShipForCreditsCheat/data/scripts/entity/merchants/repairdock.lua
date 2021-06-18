-- repair dock credits-repair cheat for hardmode.
-- allows ships to be repaired for the ludicrous credit cost normally associated with dying without a repair token.


-- namespace RepairDock

function RepairDock.onShowWindow(option)
	-- this could get called by the server at seemingly random times, so we must check that the UI was initialized
	if not window then return end

	-- repairing
	RepairDock.refreshRepairUI()

	-- reconstruction site & tokens
	RepairDock.refreshReconstructionTokens()

	-- cheats below here
	--if not GameSettings().reconstructionAllowed then
	--    tabbedWindow:deactivateTab(reconstructionTab)
	--else
	--    -- reconstructing ships
		RepairDock.refreshReconstructionLines()
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

	-- check if we can pay with tokens
	local paidWithToken = false
	local tokens, item, idx = countReconstructionTokens(buyer, shipName)
	if tokens > 0 then
		local taken = buyer:getInventory():take(idx)
		if not taken then
			player:sendChatMessage(Entity(), ChatMessageType.Error, "Token for this ship not found."%_T)
		else
			paidWithToken = true
			player:sendChatMessage(Entity(), ChatMessageType.Information, "Used a Reconstruction Token to reconstruct '%s'."%_T, shipName)
		end
	end

	if not paidWithToken then
		-- if we can't, use the (higher) reconstruction price
		local price = RepairDock.getReconstructionPrice(buyer, shipName)
		local canPay, msg, args = buyer:canPay(price)

		if not canPay then
			player:sendChatMessage(Entity(), ChatMessageType.Error, msg, unpack(args))
			return
		end

		buyer:pay("Paid %1% Credits to reconstruct a ship."%_T, price)
	end

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

	Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "Insta-Reconstruction complete! Your ship may have suffered some minor structural damages due to the reconstruction process."%_t)
	Sector():broadcastChatMessage(Entity(), ChatMessageType.Normal, "If you buy a new Reconstruction Token, we'll fix her up for free!"%_t)

	invokeClientFunction(player, "onShowWindow", 0)
end
callable(RepairDock, "reconstruct")