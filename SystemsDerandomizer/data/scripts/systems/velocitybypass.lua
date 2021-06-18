-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local energy = (6.0 - (rarity.value + 1)) * 8  -- base value 60 for worst, 0 for best rarity
	--energy = energy + getInt(0, 10) -- add a random number of 10
	energy = energy / 100

	return energy
end