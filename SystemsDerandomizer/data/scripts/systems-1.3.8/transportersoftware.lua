-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	-- rarity -1 is -1 / 2 + 1 * 50 = 0.5 * 100 = 50
	-- rarity 5 is 5 / 2 + 1 * 50 = 3.5 * 100 = 350
	local range = (rarity.value / 2 + 1 + 0.4) * 100

	local fighterCargoPickup = 0
	if rarity.value >= RarityType.Rare then
		fighterCargoPickup = 1
	end

	return range, fighterCargoPickup
end