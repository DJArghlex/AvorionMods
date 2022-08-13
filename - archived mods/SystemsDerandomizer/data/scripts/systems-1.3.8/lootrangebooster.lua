-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getLootCollectionRange(seed, rarity, permanent)
	math.randomseed(seed)

	local range = (rarity.value + 2 + 0.75) * 2 * (1.3 ^ rarity.value) -- one unit is 10 meters

	if permanent then
		range = range * 3
	end

	range = round(range)

	return range
end
