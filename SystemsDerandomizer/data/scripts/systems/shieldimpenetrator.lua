-- MODIFIES ENTIRE FUNCTION. Removes math.random, getInt, and getFloat functions from most of the code. part of rglx's systemsderandomizer mod.
function getBonuses(seed, rarity, permanent)
	math.randomseed(seed)

	local durability = 0.25
	durability = durability + (rarity.value * 0.03) + 0.03

	local rechargeTimeFactor = 4.0
	rechargeTimeFactor = rechargeTimeFactor - (rarity.value * 0.2) - 0.2

	return durability, rechargeTimeFactor
end