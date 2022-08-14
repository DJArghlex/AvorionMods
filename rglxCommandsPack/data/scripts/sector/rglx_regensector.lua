--namespace regenSector
regenSector = {}
local self = regenSector

local SectorSpecifics = include ("sectorspecifics")

function regenSector.initialize()
	if onServer() then
		--local sector = Sector() -- dereferencing this and just calling Sector() makes it more stable
		local galaxy = Galaxy()
		local server = Server()
		local x, y = Sector():getCoordinates()
		print("rglx_CmdsPack_regensector_sector: sector-script loaded into sector ("..x..":"..y..")...")


		local sectorspecs = SectorSpecifics(x, y, GameSeed()) -- this sector's specifics

		if not sectorspecs.generationTemplate then
			eprint("rglx_CmdsPack_regensector_sector: ERROR! ("..x..":"..y..") has no generation template set. Is it a player/AI home sector?")
			--Sector():removeScript("sector/rglx_regensector")
			terminate()
		end

		specsPath = sectorspecs.generationTemplate.path
		sectorspecs = nil

		for _, entity in pairs({Sector():getEntities()}) do

			if Faction(entity.factionIndex) == nil then
				Sector():deleteEntity(entity) -- delete un-factioned items (asteroids, wreckage, stashes)
			else
				if Faction(entity.factionIndex).isAIFaction then
					Sector():deleteEntity(entity) -- items owned by NPCs (stations, defenders, et cetera)
				end
			end
		end

		-- some more cleanup
		Sector():collectGarbage()

		-- send a message when the sector starts being regenerated
		print("rglx_CmdsPack_regensector_sector: Starting sector regeneration for ("..x..":"..y..")...")

		local specs = SectorSpecifics(x, y, GameSeed()) -- coordinates have to be 0,0

		-- add the templates
		specs:addTemplates()

		for _, template in pairs(specs.templates) do
			if specsPath == template.path then
				template.generate(Faction(), Sector().seed, Sector():getCoordinates())
			end
		end

		print("rglx_CmdsPack_regensector_sector: Sector regeneration for ("..x..":"..y..") completed.")
	else
		eprint("rglx_CmdsPack_regensector_sector: script was loaded clientside- this does nothing.")
	end

	--Sector():removeScript("sector/rglx_regensector")
	terminate()
end