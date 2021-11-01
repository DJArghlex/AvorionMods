-- overrides stock function
-- increases range of map to galaxywide
function run(playerIndex, factionIndex, withOffgrid, withContent, quadrant)

	local FactoryPredictor = include ("factorypredictor")
	local SectorSpecifics = include ("sectorspecifics")
	local GatesMap = include ("gatesmap")

	local timer = HighResolutionTimer()
	timer:start()

	local gatesMap = GatesMap(GameSeed())

	local player = Player(playerIndex)
	local faction = Faction(factionIndex)

	local hx, hy = faction:getHomeSectorCoordinates()

	-- +----+----+
	-- | NW | NE |
	-- | 1  | 2  |
	-- +--- H ---+
	-- | SW | SE |
	-- | 3  | 4  |
	-- +----+----+

	local startX = hx - 1000 -- changed
	local endX = hx + 1000 -- changed
	local startY = hy - 1000 -- changed
	local endY = hy + 1000 -- changed

	if quadrant then
		if quadrant == 3 then
			endX = hx
			endY = hy
		elseif quadrant == 4 then
			startX = hx
			endY = hy
		elseif quadrant == 1 then
			endX = hx
			startY = hy
		elseif quadrant == 2 then
			startX = hx
			startY = hy
		end
	end

	if startX < -500 then startX = -500 end
	if startY < -500 then startY = -500 end

	if endX > 500 then endX = 500 end
	if endY > 500 then endY = 500 end

	-- print ("h: %i %i, s: %i %i, e: %i %i, q: %i", hx, hy, startX, startY, endX, endY, quadrant)

	local specs = SectorSpecifics()

	local seed = GameSeed()
	for x = startX, endX do
		for y = startY, endY do
			local regular, offgrid, dust = specs.determineFastContent(x, y, seed)

			if regular or offgrid then
				specs:initialize(x, y, seed)

				if specs.regular and specs.factionIndex == factionIndex
						and specs.generationTemplate
						and (withOffgrid or specs.gates) then
					local view = player:getKnownSector(x, y) or SectorView()

					if not view.visited then
						specs:fillSectorView(view, gatesMap, withContent)

						player:updateKnownSectorPreserveNote(view)
					end

				end
			end
			::continuey::
		end
		::continuex::
	end

	local view = player:getKnownSector(hx, hy) or SectorView()
	view:setCoordinates(hx, hy)
	view.note = "Faction Headquarters for " .. faction.name .. %_T -- changed
	player:updateKnownSectorPreserveNote(view)

	player:setValue("block_async_execution", nil)

	player:sendChatMessage("", ChatMessageType.Information, "Map information added to the Galaxy Map."%_t)

end
