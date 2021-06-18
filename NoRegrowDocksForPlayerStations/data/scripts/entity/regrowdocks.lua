-- disables regrowdocks.lua for everything but AI faction stations.
-- by rglx, v0.1.0

-- store old regrowdocks function someplace safe
vanillaregrow = RegrowDocks.regrow
function RegrowDocks.regrow(...)
	-- determine our current faction
	faction=Faction()
	if faction.isAIFaction then -- check if it's an NPC faction
		--print("rglx-NoRegrowDocks: Regrowing docks on an AI station.")
		-- it is! run regular regrowth code
		vanillaregrow(...)
	--else
		--print("rglx-NoRegrowDocks: Not regrowing docks on this station.")
		-- it's not. it's a player or alliance-owned station and thus we don't want docks on it.
		--return
	end
end
