
function initializePlayer(player)

	local galaxy = Galaxy()
	local server = Server()

	local random = Random(server.seed)

	-- get a random angle, fixed for the server seed
	local angle = random:getFloat(2.0 * math.pi)


	-- for each player registered, add a small amount on top of this angle
	-- this way, all players are near each other
	local home = nil
	local faction

	local distFromCenter = 480.0
	local distBetweenPlayers = 1 + random:getFloat(0, 1) -- distance between the home sectors of different players

	local tries = {}

	for i = 1, 300000 do
		-- we're looking at a distance of 450, so the perimeter is ~1413
		-- with every failure we walk a distance of 3 on the perimeter, so we're finishing a complete round about every 500 failing iterations
		-- every failed round we reduce the radius by several sectors to cover a bigger area.
		local offset = math.floor(i / 500) * 5

		local coords =
		{
			x = math.cos(angle) * (distFromCenter - offset),
			y = math.sin(angle) * (distFromCenter - offset),
		}

		table.insert(tries, coords)

		-- try to place the player in the area of a faction
		faction = galaxy:getLocalFaction(coords.x, coords.y)
		if faction then
			-- found a faction we can place the player to - stop looking if we don't need different start sectors
			if server.sameStartSector then
				home = coords
				break
			end

			-- in case we need different starting sectors: keep looking
			if galaxy:sectorExists(coords.x, coords.y) then
				angle = angle + (distBetweenPlayers / distFromCenter)
			else
				home = coords
				break
			end
		else
			angle = angle + (3 / distFromCenter)
		end
	end

	if not home then
		home = randomEntry(random, tries)
		faction = galaxy:getLocalFaction(home.x, home.y)
	end

	player:setHomeSectorCoordinates(home.x, home.y)
	player:setReconstructionSiteCoordinates(home.x, home.y)
	player:setRespawnSiteCoordinates(home.x, home.y)

	-- make sure the player has an early ally
	if not faction then
		faction = galaxy:getNearestFaction(home.x, home.y)
	end

	faction:setValue("enemy_faction", -1) -- this faction won't participate in faction wars
	galaxy:setFactionRelations(faction, player, 85000)
	player:setValue("start_ally", faction.index)
	player:setValue("gates2.0", true)

	local random = Random(SectorSeed(home.x, home.y) + player.index)
	local settings = GameSettings()

	if settings.startingResources == -4 then -- -4 means quick start
		player:receive(250000, 25000, 15000)
	elseif settings.startingResources == Difficulty.Beginner then
		player:receive(50000, 5000)
	elseif settings.startingResources == Difficulty.Easy then
		player:receive(40000, 2000)
	elseif settings.startingResources == Difficulty.Normal then
		player:receive(30000)
	else
		player:receive(10000)
	end

	-- create turret generator
	local generator = SectorTurretGenerator()

	local miningLaser = InventoryTurret(generator:generate(450, 0, nil, Rarity(RarityType.Common), WeaponType.MiningLaser, Material(MaterialType.Iron)))
	for i = 1, 2 do
		player:getInventory():add(miningLaser, false)
	end

	local chaingun = InventoryTurret(generator:generate(450, 0, nil, Rarity(RarityType.Common), WeaponType.ChainGun, Material(MaterialType.Iron)))
	for i = 1, 2 do
		player:getInventory():add(chaingun, false)
	end

	if settings.playTutorial then
		-- extra inventory items for tutorial: One arbitrary tcs, three more armed turrets with the name used in the text of tutorial stage
		local upgrade = SystemUpgradeTemplate("data/scripts/systems/arbitrarytcs.lua", Rarity(RarityType.Uncommon), Seed(121))
		player:getInventory():add(upgrade, true)

		chaingun.title = "Chaingun /* Weapon Type */"%_T
		player:getInventory():add(chaingun, false)
		player:getInventory():add(chaingun, false)
		player:getInventory():add(chaingun, false)

		-- start with 750 iron and 30.000 credits into tutorial independent of difficulty
		player.money = 30000
		player:setResources(750, 0, 0, 0, 0, 0, 0, 0)
	else
		if server.difficulty <= Difficulty.Normal then

			local upgrade = SystemUpgradeTemplate("data/scripts/systems/arbitrarytcs.lua", Rarity(RarityType.Uncommon), Seed(1))
			player:getInventory():add(upgrade, true)

			player:receive(0, 7500)

			for i = 1, 2 do
				player:getInventory():add(miningLaser, false)
				player:getInventory():add(chaingun, false)
			end
		end
	end

	if settings.fullBuildingUnlocked then
		player.maxBuildableMaterial = Material(MaterialType.Avorion)
	else
		player.maxBuildableMaterial = Material(MaterialType.Iron)
	end

	if settings.unlimitedProcessingPower or settings.fullBuildingUnlocked then
		player.maxBuildableSockets = 0
	else
		player.maxBuildableSockets = 4
	end
end